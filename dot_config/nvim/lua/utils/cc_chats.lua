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
      table.insert(entries, vim.tbl_extend("force", restored[e.bufnr], { title = chat.title ~= "" and chat.title or nil }))
    elseif chat and chat.adapter.type == "acp" and conn and conn.session_id and chat.cycle > 1 then
      table.insert(entries, {
        adapter = chat.adapter.name,
        session_id = conn.session_id,
        title = chat.title ~= "" and chat.title or nil,
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
      if entry.title then
        chat:set_title(entry.title)
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
