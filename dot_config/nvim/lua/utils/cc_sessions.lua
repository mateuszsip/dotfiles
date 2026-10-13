-- Custom session management for CodeCompanion (works on top of the plugin's own
-- sessions storage). Adds session deletion from the /resume picker.
local M = {}

---Delete a saved session by stem, or by session table.
function M.delete(stem)
  local ok, sessions = pcall(require, "codecompanion.interactions.chat.sessions")
  if not ok or not sessions then
    vim.notify("CodeCompanion sessions unavailable", vim.log.levels.WARN)
    return
  end
  sessions.delete(stem)
end

---Open the resume picker using Snacks, allowing <c-d> to delete a session.
local function make_picker(sessions, utils)
  local open
  open = function(opts)
    opts = opts or {}
    local list = sessions.list()
    if vim.tbl_isempty(list) then
      return utils.notify("No saved sessions found", vim.log.levels.INFO)
    end

    Snacks.picker({
      title = "Resume Session (<m-d> delete)",
      finder = function()
        return vim.tbl_map(function(s)
          return { text = sessions.format(s), stem = s.stem }
        end, sessions.list())
      end,
      actions = {
        delete_session = function(picker, item)
          if not item then
            return
          end
          sessions.delete(item.stem, { notify = false })
          if vim.tbl_isempty(sessions.list()) then
            picker:close()
            utils.notify("No saved sessions found", vim.log.levels.INFO)
          else
            picker:find()
          end
        end,
      },
      win = {
        input = { keys = { ["<m-d>"] = { "delete_session", mode = { "i", "n" } } } },
        list = { keys = { ["<m-d>"] = "delete_session" } },
      },
      preview = false,
      confirm = function(picker, item)
        picker:close()
        if not item then
          return
        end
        vim.schedule(function()
          local chat = sessions.load(item.stem, { buffer_context = opts.buffer_context })
          if chat and opts.on_restored then
            opts.on_restored(chat)
          end
        end)
      end,
    })
  end
  return open
end

function M.setup()
  local has_snacks, Snacks = pcall(require, "snacks")
  if not has_snacks or not Snacks or not Snacks.picker then
    return
  end

  local has_sessions, sessions = pcall(require, "codecompanion.interactions.chat.sessions")
  if not has_sessions or not sessions or not sessions.list then
    return
  end

  local utils = require("codecompanion.utils")
  local open = make_picker(sessions, utils)

  sessions.select = function(opts)
    open(opts)
  end
end

return M
