local M = {}

--- Foldexpr for PHP: groups consecutive `use` import lines into a fold,
--- falls back to treesitter for everything else.
function M.foldexpr(lnum)
  if vim.fn.getline(lnum):match("^use ") then
    return "1"
  end
  return "0"
end

--- Close the import fold and restore cursor position.
function M.auto_close_imports()
  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for i, line in ipairs(lines) do
    if line:match("^use ") then
      local saved = vim.api.nvim_win_get_cursor(0)
      vim.api.nvim_win_set_cursor(0, { i, 0 })
      pcall(vim.cmd, "normal! zc")
      vim.api.nvim_win_set_cursor(0, saved)
      break
    end
  end
end

return M
