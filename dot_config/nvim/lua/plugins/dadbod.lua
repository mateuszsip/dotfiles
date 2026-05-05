return {
  "tpope/vim-dadbod",
  dependencies = {
    "kristijanhusak/vim-dadbod-ui",
  },
  lazy = true,
  config = function()
    local function vault_db_url(vault_path, scheme, host, port, dbname)
      local raw = vim.fn.system("vault read -format=json " .. vault_path)
      local ok, data = pcall(vim.json.decode, raw)
      if not ok or not data.data then
        error("Failed to read Vault credentials: " .. raw)
      end
      local u = data.data.username
      local p = data.data.password
      -- URL-encode password to handle special characters
      p = p:gsub("([^%w%-_%.~])", function(c)
        return string.format("%%%02X", c:byte())
      end)
      return string.format("%s://%s:%s@%s:%s/%s", scheme, u, p, host, port, dbname)
    end

    local function refresh_db_credentials()
      local dbs = {}

      -- Auto-load all source files from lua/db/ (recurses into subdirectories)
      local db_dir = vim.fn.stdpath("config") .. "/lua/db"
      local files = vim.fn.glob(db_dir .. "/**/*.lua", false, true)

      for _, file in ipairs(files) do
        -- Derive module name from path relative to lua/, e.g. db/lendable/prestg
        local rel = file:match(".*[/\\]lua[/\\](.+)%.lua$"):gsub("[/\\]", ".")
        local mod = rel
        package.loaded[mod] = nil
        local ok, source = pcall(require, mod)
        if not ok then
          vim.notify("Failed to load DB source " .. mod .. ": " .. source, vim.log.levels.ERROR)
        elseif type(source) ~= "table" then
          -- empty file or module returns non-table; skip silently
        else
          for _, entry in ipairs(source) do
            local ok_url, url
            if entry.vault_role then
              local host = entry.host or os.getenv(entry.host_env)
              local scheme = entry.scheme or "mysql"
              local port = entry.port or 3306
              ok_url, url = pcall(vault_db_url, "database/creds/" .. entry.vault_role, scheme, host, port, entry.dbname)
            elseif type(entry.url) == "function" then
              ok_url, url = pcall(entry.url)
            else
              ok_url, url = true, entry.url
            end
            if ok_url then
              table.insert(dbs, { name = entry.name, url = url })
            else
              vim.notify("Failed to get credentials for " .. entry.name .. ": " .. url, vim.log.levels.ERROR)
            end
          end
        end
      end

      vim.g.dbs = dbs
    end

    refresh_db_credentials()

    vim.keymap.set("n", "<leader>Dr", function()
      refresh_db_credentials()
      vim.notify("DB credentials refreshed from Vault")
    end, { desc = "Refresh DB credentials from Vault" })
  end,
}
