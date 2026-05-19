-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.relativenumber = true
vim.g.trouble_lualine = false -- managed manually in lualine.lua with a cleaner format
-- Use nushell for :terminal; keep POSIX shell for plugin commands
if vim.fn.executable("nu") == 1 then
  vim.opt.shell = "nu"
  vim.opt.shellcmdflag = "-c"
  vim.opt.shellquote = ""
  vim.opt.shellxquote = ""
end
