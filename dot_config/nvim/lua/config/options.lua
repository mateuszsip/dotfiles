-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.relativenumber = true

-- Treat Unicode "ambiguous width" characters (●, •, ○, etc.) as 2 cells wide,
-- matching how the terminal renders them. Without this, render-markdown.nvim's
-- overflow detection underestimates icon widths and uses overlay mode instead
-- of inline+conceal mode, causing icons to visually consume the space after
-- list markers (e.g. "•item" instead of "• item").
vim.opt.ambiwidth = "double"
