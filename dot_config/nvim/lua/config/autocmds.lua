-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local function apply_hl_overrides()
  -- Thin window separators (flexoki sets fg=bg, making a solid block)
  vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#CECDC3", bg = "NONE" })
  -- Bullet markers: transparent bg so they don't paint paper-white onto code block beige.
  vim.api.nvim_set_hl(0, "RenderMarkdownBullet", { bg = "NONE" })
  -- Code blocks: warm parchment beige (warmer than flexoki-50, cooler than paper).
  local code_bg = "#EBE7D2"
  vim.api.nvim_set_hl(0, "RenderMarkdownCode",     { bg = code_bg })
  vim.api.nvim_set_hl(0, "RenderMarkdownCodeLang", { fg = "#403E3C", bg = code_bg })
  vim.api.nvim_set_hl(0, "RenderMarkdownCodeInfo", { fg = "#403E3C", bg = code_bg })
end

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    apply_hl_overrides()
  end,
})
apply_hl_overrides()

-- Markdown editing keymaps live in after/ftplugin/markdown.lua.

vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    vim.api.nvim_set_hl(0, "NeotestPassed",  { fg = "#22863a" })
    vim.api.nvim_set_hl(0, "NeotestRunning", { fg = "#b59f0a" })
    vim.api.nvim_set_hl(0, "NeotestDir",       { fg = "#6b9ab8" })
    vim.api.nvim_set_hl(0, "NeotestFile",      { fg = "#6b9ab8" })
    vim.api.nvim_set_hl(0, "NeotestSkipped",   { fg = "#6b9ab8" })
    vim.api.nvim_set_hl(0, "NeotestNamespace", { fg = "#8ab4cc" })
    -- Subtle diff backgrounds that let syntax highlighting show through
    -- (flexoki overrides fg with the paper color, washing out all syntax colors)
    vim.api.nvim_set_hl(0, "DiffAdd",    { bg = "#e6edcc" })
    vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#f7dbd9" })
    vim.api.nvim_set_hl(0, "DiffChange", { bg = "#e8e0f0" })
    vim.api.nvim_set_hl(0, "DiffText",   { bg = "#d5e5f5", bold = true })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function()
    vim.schedule(function()
      local win_type = vim.fn.win_gettype(0)
      if win_type == "loclist" then
        vim.cmd("lclose")
        require("trouble").open({ mode = "loclist", focus = true, open_folds = false })
      else
        vim.cmd("cclose")
        require("trouble").open({ mode = "quickfix", focus = true, open_folds = false })
      end
    end)
  end,
})

-- Wipe directory buffers, and oil buffers too when a session is about to
-- read or write them, to keep the restored window layout stable.
local function wipe_session_bufs(oil_too)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      local bufname = vim.api.nvim_buf_get_name(buf)
      if vim.fn.isdirectory(bufname) == 1 or (oil_too and bufname:match("^oil://")) then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
    end
  end
end

-- Wipeout directory and oil buffers before saving/loading session to prevent window size/layout distortion
vim.api.nvim_create_autocmd("User", {
  pattern = { "PersistenceSavePre", "PersistenceLoadPre" },
  group = vim.api.nvim_create_augroup("PersistenceBufferCleanup", { clear = true }),
  desc = "Wipeout directory and oil buffers before saving or loading session",
  callback = function()
    wipe_session_bufs(true)
  end,
})

-- Wipeout directory buffers after session load
vim.api.nvim_create_autocmd("User", {
  pattern = "PersistenceLoadPost",
  group = vim.api.nvim_create_augroup("PersistenceDirectoryCleanup", { clear = true }),
  desc = "Clean directory buffers after session load",
  callback = function()
    wipe_session_bufs(false)
  end,
})

