--- Collect the database connections declared under `lua/db/` and publish them
--- as `vim.g.dbs`, the list both vim-dadbod and dadbod-grip read.
---
--- Credentials are embedded in the URL (percent-encoded), not referenced
--- through `$VAR` placeholders: vim-dadbod expands `$VAR` while dadbod-grip
--- expands `${VAR}`, so no single placeholder form keeps both happy. The
--- lease therefore lives in `vim.g.dbs` for the session - see
--- plugins/dadbod-grip.lua for keeping grip's on-disk registry off disk.
local M = {}

---Percent-encode a URL component. Both consumers paste the password into the
---URL as-is, so it has to be URL-safe before it gets there.
---@param value string
---@return string
local function encode(value)
  return (value:gsub("([^%w%-_%.~])", function(char)
    return string.format("%%%02X", char:byte())
  end))
end

---Read a Vault dynamic database credential.
---@param vault_path string e.g. "database/creds/lendable-prestg"
---@return string|nil username
---@return string|nil password
---@return string|nil error
local function vault_read(vault_path)
  local raw = vim.fn.system({ "vault", "read", "-format=json", vault_path })
  if vim.v.shell_error ~= 0 then
    return nil, nil, "vault read failed: " .. vim.trim(raw)
  end
  local ok, decoded = pcall(vim.json.decode, raw)
  if not ok or type(decoded) ~= "table" or type(decoded.data) ~= "table" then
    return nil, nil, "unexpected vault output: " .. vim.trim(raw)
  end
  local username, password = decoded.data.username, decoded.data.password
  if type(username) ~= "string" or type(password) ~= "string" then
    return nil, nil, "vault returned no username/password for " .. vault_path
  end
  return username, password
end

---Port to fall back to when an entry omits one.
---@param scheme string
---@return integer
local function default_port(scheme)
  return scheme:match("^postgres") and 5432 or 3306
end

---Build a connection URL for a `vault_role` entry from a fresh lease.
---@param entry table one entry returned by a `lua/db/**` module
---@return string|nil url
---@return string|nil error
local function vault_url(entry)
  local scheme = entry.scheme or "mysql"
  local host = entry.host or (entry.host_env and os.getenv(entry.host_env))
  if not host then
    return nil, ("no host and $%s is unset"):format(tostring(entry.host_env))
  end
  if not entry.dbname then
    return nil, "entry has no dbname"
  end

  local username, password, err = vault_read("database/creds/" .. entry.vault_role)
  if not username then
    return nil, err
  end

  return ("%s://%s:%s@%s:%s/%s"):format(
    scheme,
    encode(username),
    encode(password),
    host,
    tostring(entry.port or default_port(scheme)),
    entry.dbname
  )
end

---Resolve one entry into a connection URL.
---@param entry table
---@return string|nil url
---@return string|nil error
local function resolve(entry)
  if entry.vault_role then
    return vault_url(entry)
  end
  if type(entry.url) == "function" then
    local ok, url = pcall(entry.url)
    return ok and url or nil, ok and nil or tostring(url)
  end
  return entry.url
end

---Every connection declared under `lua/db/`, with credentials resolved.
---@return { name: string, url: string }[] connections
---@return string[] problems
function M.entries()
  local db_dir = vim.fn.stdpath("config") .. "/lua/db"
  local connections, problems = {}, {}

  for _, file in ipairs(vim.fn.glob(db_dir .. "/**/*.lua", false, true)) do
    -- Derive the module name from the path relative to lua/, e.g.
    -- db/lendable/prestg -> db.lendable.prestg
    local rel = file:match(".*[/\\]lua[/\\](.+)%.lua$")
    local mod = rel and rel:gsub("[/\\]", ".")
    if mod then
      package.loaded[mod] = nil -- pick up edits without restarting
      local ok, source = pcall(require, mod)
      if not ok then
        table.insert(problems, ("%s: %s"):format(mod, source))
      elseif type(source) == "table" then
        for _, entry in ipairs(source) do
          local url, err = resolve(entry)
          if url then
            table.insert(connections, { name = entry.name, url = url })
          else
            table.insert(problems, ("%s: %s"):format(entry.name or mod, err))
          end
        end
      end
    end
  end

  return connections, problems
end

---Refresh `vim.g.dbs` from the `lua/db/**` sources.
---@return { name: string, url: string }[] connections
function M.refresh()
  local connections, problems = M.entries()
  for _, problem in ipairs(problems) do
    vim.notify("DB connection: " .. problem, vim.log.levels.ERROR)
  end
  vim.g.dbs = connections
  return connections
end

return M
