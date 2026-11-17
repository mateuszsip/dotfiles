-- Keep the oil browser out of the way unless it is the only thing to show.
--
-- Oil is a filesystem view, not a document. Directory buffers, restored
-- sessions and `nvim . file` all let it sit in the buffer list next to real
-- files, where it takes a slot when cycling buffers and can take over the
-- main window. Floats (<leader>e etc.) are untouched: prune() only runs at
-- startup / after a session restore, never while oil is being used.

local M = {}

--- Listed buffers backed by a real file (no unnamed scratch, no URI schemes).
---@param except integer|nil
---@return integer[]
local function file_buffers(except)
  return vim.tbl_filter(function(buf)
    local name = vim.api.nvim_buf_get_name(buf)
    return buf ~= except
      and vim.api.nvim_buf_is_valid(buf)
      and vim.bo[buf].buflisted
      and name ~= ""
      and not name:match("^%a[%w+.-]*://")
  end, vim.api.nvim_list_bufs())
end

--- Delete oil buffers when any real file buffer exists, otherwise leave them.
--- Windows showing an oil buffer are switched to a file buffer first.
function M.prune()
  local oils = vim.tbl_filter(function(buf)
    return vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_name(buf):match("^oil://") ~= nil
  end, vim.api.nvim_list_bufs())
  local files = file_buffers(nil)
  if #oils == 0 or #files == 0 then
    return
  end

  local keep = files[1]
  for _, buf in ipairs(oils) do
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == buf and vim.api.nvim_win_get_config(win).relative == "" then
        vim.api.nvim_win_set_buf(win, keep)
      end
    end
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end

  for _, arg in ipairs(vim.fn.argv()) do
    if arg:match("^oil://") then
      pcall(vim.cmd, "argdelete " .. vim.fn.escape(arg, "\\*?[]"))
    end
  end
end

return M
