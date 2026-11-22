-- Keep the CodeCompanion chat visible when a plugin moves into its own tab.
--
-- atlas.nvim hardcodes `tabnew` for its PR/issue panel, so opening atlas always
-- leaves the tab the chat was in. CodeCompanion's `display.chat.window.sticky`
-- (set in plugins/codecompanion.lua) moves the chat into the tab you enter, but
-- only while its window still exists: closing the atlas tab closes the chat
-- window with it, and sticky then has nothing to move. This remembers the chat
-- visible in the tab being left and reopens it when the tab entered shows none.
local M = {}

---Chat shown in the current tab, preferring the one CodeCompanion treats as
---"last" (the one `sticky` moves).
---@return CodeCompanion.Chat|nil
local function visible_chat()
  local cc = require("codecompanion")
  local last = cc.last_chat()
  local found
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local chat = cc.buf_get_chat(vim.api.nvim_win_get_buf(win))
    if chat then
      if last and chat.bufnr == last.bufnr then
        return chat
      end
      found = found or chat
    end
  end
  return found
end

function M.setup()
  local group = vim.api.nvim_create_augroup("cc_tabs_sticky", { clear = true })
  local remembered

  vim.api.nvim_create_autocmd("TabLeave", {
    group = group,
    callback = function()
      -- don't lazy-load CodeCompanion just because a tab was switched
      if not package.loaded["codecompanion"] then
        return
      end
      remembered = visible_chat()
    end,
  })

  vim.api.nvim_create_autocmd("TabEnter", {
    group = group,
    callback = function()
      local chat = remembered
      if not chat or vim.fn.bufwinid(chat.bufnr) ~= -1 then
        return
      end
      -- deferred so CodeCompanion's own sticky handler (which may be about to
      -- move the chat here) and the new tab's layout settle first
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(chat.bufnr) and vim.fn.bufwinid(chat.bufnr) == -1 then
          chat.ui:open({ toggled = true })
        end
      end)
    end,
  })
end

return M
