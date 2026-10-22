-- Live nvim server sessions: the in-editor view of ~/.local/bin/nv.
--
-- A detached nvim is just a server with no UI attached (nvim 0.12 `:detach`).
-- `nv` pins one socket per project under $XDG_RUNTIME_DIR/nvim-sessions and
-- leaves a .meta beside it recording the directory it was started from. This
-- module reads that directory, so you can see the running editors and move
-- the current UI onto one of them with `:connect` — no shell needed.
--
-- Everything is read-only apart from `:connect`; quitting or reaping a
-- session stays in the wrapper's hands (`nv -k`), where the unsaved-changes
-- check lives.

local M = {}

-- Same resolution as the wrapper in ~/.local/bin/nv: $XDG_RUNTIME_DIR on
-- Linux, otherwise a path inside the state home (macOS has no runtime dir,
-- and $TMPDIR differs between a login shell and a launchd agent).
local function state_dir()
  local runtime = vim.env.XDG_RUNTIME_DIR
  if runtime and runtime ~= "" then
    return (runtime:gsub("/+$", "")) .. "/nvim-sessions"
  end
  local state = vim.env.XDG_STATE_HOME
  if not state or state == "" then
    state = (vim.env.HOME or "") .. "/.local/state"
  end
  return (state:gsub("/+$", "")) .. "/nvim/run"
end

--- Directory holding the live sockets (useful when a session looks missing).
function M.dir()
  return state_dir()
end

--- Attached UI count for the server at `sock`; nil when nothing answers.
local function ui_count(sock)
  local ok, chan = pcall(vim.fn.sockconnect, "pipe", sock, { rpc = true })
  if not ok or chan == 0 then
    return nil
  end
  local asked, count = pcall(vim.rpcrequest, chan, "nvim_eval", "len(nvim_list_uis())")
  pcall(vim.fn.chanclose, chan)
  if not asked then
    return nil
  end
  return tonumber(count)
end

local function cwd_of(key)
  local ok, lines = pcall(vim.fn.readfile, state_dir() .. "/" .. key .. ".meta")
  if ok then
    for _, line in ipairs(lines) do
      local cwd = line:match("^cwd=(.+)$")
      if cwd then
        return cwd
      end
    end
  end
  -- Fall back to the key itself: %home%sip%code -> /home/sip/code.
  return (key:gsub("%%", "/"):gsub("^~", vim.env.HOME or "~"))
end

local function age_of(seconds)
  if seconds >= 86400 then
    return string.format("%dd%dh", math.floor(seconds / 86400), math.floor(seconds % 86400 / 3600))
  elseif seconds >= 3600 then
    return string.format("%dh%02dm", math.floor(seconds / 3600), math.floor(seconds % 3600 / 60))
  elseif seconds >= 60 then
    return string.format("%dm", math.floor(seconds / 60))
  end
  return string.format("%ds", seconds)
end

--- Every live session, sorted by directory. Dead sockets are skipped.
---@return table[] { key, sock, cwd, uis, age }
function M.list()
  local dir = state_dir()
  local handle = vim.uv.fs_scandir(dir)
  if not handle then
    return {}
  end

  local out = {}
  while true do
    local name = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end
    local key = name:match("^(.*)%.sock$")
    if key then
      local sock = dir .. "/" .. name
      local uis = ui_count(sock)
      if uis then
        local stat = vim.uv.fs_stat(sock)
        out[#out + 1] = {
          key = key,
          sock = sock,
          cwd = cwd_of(key),
          uis = uis,
          age = stat and age_of(os.time() - stat.mtime.sec) or "?",
        }
      end
    end
  end

  table.sort(out, function(a, b)
    return a.cwd < b.cwd
  end)
  return out
end

--- Pick a running server and move this UI onto it (`:connect`).
function M.pick()
  local sessions = M.list()
  if #sessions == 0 then
    return vim.notify("No nvim sessions running — start one with `nv`", vim.log.levels.INFO)
  end

  local me = vim.v.servername
  local items = {}
  for _, session in ipairs(sessions) do
    items[#items + 1] = vim.tbl_extend("force", session, { self = session.sock == me })
  end

  Snacks.picker({
    title = "Live nvim sessions",
    items = items,
    format = function(item)
      local home = vim.env.HOME or "~"
      local chunks = {
        { vim.fn.fnamemodify(item.cwd, ":t"), "SnacksPickerFile" },
        { item.uis == 0 and "  detached" or ("  attached ×" .. item.uis), "SnacksPickerComment" },
        { "  " .. (item.cwd:gsub("^" .. vim.pesc(home), "~")), "SnacksPickerDir" },
        { "  " .. item.age, "SnacksPickerComment" },
      }
      if item.self then
        chunks[#chunks + 1] = { "  (this UI)", "SnacksPickerComment" }
      end
      return chunks
    end,
    confirm = function(picker, item)
      picker:close()
      if not item then
        return
      end
      if item.self then
        return vim.notify("Already attached to that session", vim.log.levels.INFO)
      end
      if vim.fn.exists(":connect") ~= 2 then
        return vim.notify(":connect needs nvim 0.12", vim.log.levels.WARN)
      end
      vim.cmd("connect " .. vim.fn.fnameescape(item.sock))
    end,
  })
end

return M
