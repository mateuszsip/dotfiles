-- Remember open CodeCompanion ACP chats per cwd across Neovim sessions.
-- Saved on VimLeavePre; restored on startup and on demand with <leader>aL
-- (restoring spawns the agents). Startup opens a fresh chat when nothing is
-- saved. Inside `nv`, lua/utils/nv_sessions.lua runs the startup step itself,
-- after its snapshot has set the cwd and a UI has attached.
local M = {}

-- bufnr -> saved entry, for restored chats: they keep their place in the save
-- list until they have an exchange of their own (restoring does not bump
-- `cycle`), and even while their session is still loading
local restored = {}

-- opencode session id -> { title, slug, at }; the picker finder can run on
-- every keystroke, so avoid spawning sqlite3 for an unchanged session
local name_cache = {}
local NAME_CACHE_TTL = 5

local file = vim.fn.stdpath("data") .. "/codecompanion_open_chats.json"

local function cwd()
  return vim.uv.cwd() or vim.fn.getcwd()
end

local function read()
  local f = io.open(file, "r")
  if not f then
    return {}
  end
  local content = f:read("*a")
  f:close()
  local ok, data = pcall(vim.json.decode, content)
  return ok and type(data) == "table" and data or {}
end

local function write(data)
  local f = io.open(file, "w")
  if f then
    f:write(vim.json.encode(data))
    f:close()
  end
end

---OpenCode keeps the generated title/slug in its own database; CodeCompanion
---drops the session_info_update notification while it loads a saved session, so
---use the stored name as a fallback for pickers and the Waybar tooltip.
---@param chat CodeCompanion.Chat|nil
---@return string|nil title, string|nil slug
local function opencode_name(chat)
  local adapter = chat and chat.adapter
  if not (adapter and adapter.name == "opencode") then
    return nil
  end
  local sid = chat.acp_connection and chat.acp_connection.session_id
  if not sid or not sid:match("^[%w_]+$") then
    return nil
  end
  local cached = name_cache[sid]
  if cached and os.time() - cached.at < NAME_CACHE_TTL then
    return cached.title, cached.slug
  end
  if vim.fn.executable("sqlite3") == 0 then
    return nil
  end
  local data = vim.env.XDG_DATA_HOME
  if not data or data == "" then
    data = vim.fn.expand("~/.local/share")
  end
  local db = data .. "/opencode/opencode.db"
  if vim.fn.filereadable(db) == 0 then
    return nil
  end
  for _, table in ipairs({ "session_v2", "session" }) do
    local out = vim.fn.system({
      "sqlite3",
      "-readonly",
      "-json",
      db,
      ("select coalesce(title, '') as title, coalesce(slug, '') as slug from %s where id = '%s' limit 1;"):format(
        table,
        sid
      ),
    })
    if vim.v.shell_error == 0 then
      local ok, rows = pcall(vim.json.decode, out or "")
      local row = ok and type(rows) == "table" and rows[1] or nil
      if row and (row.title ~= "" or row.slug ~= "") then
        name_cache[sid] = { title = row.title, slug = row.slug, at = os.time() }
        return row.title, row.slug
      end
    end
  end
  return nil
end

---Best name for display: the chat title, then the agent's stored title, then
---the agent's session slug. The slug is display-only so a later generated
---title can replace it.
---@param chat CodeCompanion.Chat|nil
---@return string|nil name, string|nil title
function M.display_name(chat)
  if not chat then
    return nil
  end
  if type(chat.title) == "string" and chat.title ~= "" then
    return chat.title, chat.title
  end
  local title, slug = opencode_name(chat)
  if title and title ~= "" then
    return title, title
  end
  if slug and slug ~= "" then
    return slug, nil
  end
  return nil
end

---The real title to persist; a slug is only a display fallback.
---@param chat CodeCompanion.Chat|nil
---@return string|nil
function M.title_for(chat)
  local _, title = M.display_name(chat)
  return title
end

--- Record the open ACP chats that have had at least one exchange
function M.save()
  if not package.loaded["codecompanion"] then
    return
  end
  local registry = require("codecompanion.interactions.shared.registry")
  local entries = {}
  for _, e in ipairs(registry.list()) do
    local chat = e.interaction == "chat" and require("codecompanion").buf_get_chat(e.bufnr) or nil
    local conn = chat and chat.acp_connection
    if chat and chat.cycle == 1 and restored[e.bufnr] then
      table.insert(entries, vim.tbl_extend("force", restored[e.bufnr], { title = M.title_for(chat) }))
    elseif chat and chat.adapter.type == "acp" and conn and conn.session_id and chat.cycle > 1 then
      table.insert(entries, {
        adapter = chat.adapter.name,
        session_id = conn.session_id,
        title = M.title_for(chat),
      })
    end
  end
  local data = read()
  data[cwd()] = #entries > 0 and entries or nil
  write(data)
end

--- Create a chat and load a previous ACP session into it (mirrors the /resume slash command)
local function restore_one(entry, window_opts)
  local ok, adapter = pcall(require("codecompanion.adapters").resolve, entry.adapter)
  if not ok then
    return vim.notify("CodeCompanion: unknown adapter " .. entry.adapter, vim.log.levels.WARN)
  end
  local chat = require("codecompanion.interactions.chat").new({
    adapter = adapter,
    buffer_context = require("codecompanion.utils.context").get(vim.api.nvim_get_current_buf()),
    window_opts = window_opts,
  })
  if not chat then
    return
  end
  restored[chat.bufnr] = entry

  local tries = 0
  local timer = vim.uv.new_timer()
  timer:start(
    200,
    200,
    vim.schedule_wrap(function()
      tries = tries + 1
      local conn = chat.acp_connection
      if not (conn and conn.session_id) then
        if tries > 100 then
          timer:stop()
          timer:close()
          vim.notify("CodeCompanion: timed out connecting " .. entry.adapter, vim.log.levels.WARN)
        end
        return
      end
      timer:stop()
      timer:close()

      local updates = {}
      local loaded = conn:load_session(entry.session_id, {
        on_session_update = function(update)
          table.insert(updates, update)
        end,
      })
      if not loaded then
        return vim.notify("CodeCompanion: failed to load session " .. entry.session_id, vim.log.levels.ERROR)
      end
      require("codecompanion.interactions.chat.acp.commands").link_buffer_to_session(chat.bufnr, conn.session_id)
      require("codecompanion.interactions.chat.acp.render").restore_session(chat, updates)
      local title = entry.title
      if not title or title == "" then
        title = M.title_for(chat)
      end
      if title and title ~= "" then
        chat:set_title(title)
      end
    end)
  )
end

--- Restore the chats that were open in this cwd when Neovim last exited
---@param window_opts? table window options for the first chat
---@return boolean restored whether anything was saved
function M.restore(window_opts)
  local entries = read()[cwd()]
  if not entries or #entries == 0 then
    vim.notify("No saved CodeCompanion chats for this directory", vim.log.levels.INFO)
    return false
  end
  for i, entry in ipairs(entries) do
    restore_one(entry, i == 1 and window_opts or nil)
  end
  return true
end

--- Startup: restore this cwd's chats, or open a fresh one when none are saved.
--- A no-op if chats are already open, so they are never doubled.
function M.startup()
  if package.loaded["codecompanion"] and #require("codecompanion").buf_get_chat() > 0 then
    return
  end
  -- an empty start (bare `nvim`, a fresh `nv` server) leaves an unnamed
  -- scratch window; the first chat takes it over instead of splitting beside it
  local buf = vim.api.nvim_get_current_buf()
  local blank = vim.api.nvim_buf_get_name(buf) == ""
    and vim.bo[buf].buftype == ""
    and not vim.bo[buf].modified
    and vim.api.nvim_buf_line_count(buf) == 1
    and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == ""
  local window_opts = blank and { layout = "buffer" } or nil

  local entries = read()[cwd()]
  if entries and #entries > 0 then
    M.restore(window_opts)
  else
    require("codecompanion.interactions.chat").new({
      buffer_context = require("codecompanion.utils.context").get(buf),
      window_opts = window_opts,
    })
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("cc_chats_save", { clear = true })
  vim.api.nvim_create_autocmd("VimLeavePre", { group = group, callback = M.save })
  vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    callback = function()
      -- `nv` restores after its snapshot; headless runs (scripts, Lazy sync) get no agents
      if (vim.env.NV_SESSION_KEY or "") ~= "" or #vim.api.nvim_list_uis() == 0 then
        return
      end
      vim.schedule(M.startup)
    end,
  })
end

return M
