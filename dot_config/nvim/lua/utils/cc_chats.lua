-- Remember open CodeCompanion ACP chats per cwd across Neovim sessions.
-- Saved on VimLeavePre; restored on demand (restoring spawns the agents).
local M = {}

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
    if chat and chat.adapter.type == "acp" and conn and conn.session_id and chat.cycle > 1 then
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
local function restore_one(entry)
  local ok, adapter = pcall(require("codecompanion.adapters").resolve, entry.adapter)
  if not ok then
    return vim.notify("CodeCompanion: unknown adapter " .. entry.adapter, vim.log.levels.WARN)
  end
  local chat = require("codecompanion.interactions.chat").new({
    adapter = adapter,
    buffer_context = require("codecompanion.utils.context").get(vim.api.nvim_get_current_buf()),
  })
  if not chat then
    return
  end

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
function M.restore()
  local entries = read()[cwd()]
  if not entries or #entries == 0 then
    return vim.notify("No saved CodeCompanion chats for this directory", vim.log.levels.INFO)
  end
  for _, entry in ipairs(entries) do
    restore_one(entry)
  end
end

function M.setup()
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = vim.api.nvim_create_augroup("cc_chats_save", { clear = true }),
    callback = M.save,
  })
end

return M
