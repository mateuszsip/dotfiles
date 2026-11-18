-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.relativenumber = true
vim.g.trouble_lualine = false -- managed manually in lualine.lua with a cleaner format
vim.g.lazyvim_php_lsp = "phpantom_lsp"
-- Use nushell for :terminal; keep POSIX shell for plugin commands
if vim.fn.executable("nu") == 1 then
  vim.opt.shell = "nu"
  vim.opt.shellcmdflag = "-c"
  vim.opt.shellquote = ""
  vim.opt.shellxquote = ""
end

-- Rex panes (rexia): no clipboard tool exists there — the rex server strips
-- WAYLAND_DISPLAY, so wl-copy never runs — and LazyVim's clipboard=unnamedplus
-- stops nvim from auto-picking the OSC 52 provider (nvim skips auto OSC 52
-- whenever 'clipboard' is set). Force the provider, so yanks still reach the
-- system clipboard through the terminal, as they do in ghostty via wl-copy.
-- Paste from the system clipboard stays ctrl+shift+v: the pane never answers
-- an OSC 52 read query, so the paste side returns nothing instead of hanging.
local has_osc52, osc52 = pcall(require, "vim.ui.clipboard.osc52")
if vim.env.TERM == "xterm-rex" and has_osc52 then
  vim.g.clipboard = {
    name = "OSC 52 (rex pane)",
    copy = {
      ["+"] = osc52.copy("+"),
      ["*"] = osc52.copy("*"),
    },
    paste = {
      ["+"] = function() return {} end,
      ["*"] = function() return {} end,
    },
  }
end
