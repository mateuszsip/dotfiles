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

-- Bufferline re-applies its own highlights on ColorScheme, overriding anything
-- set in opts.highlights. Override BOTH BufferLine* AND native TabLine* groups
-- via defer_fn so we run well after bufferline's own scheduled setup.
local function apply_bufferline_bg()
  local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
  local bg = normal.bg or 0xFFFCF0  -- fallback: flexoki-light paper
  local sep = 0xCECDC3

  -- Native Vim tabline groups (bufferline delegates fill colour here).
  vim.api.nvim_set_hl(0, "TabLineFill", { bg = bg })
  vim.api.nvim_set_hl(0, "TabLine",     { bg = bg })
  vim.api.nvim_set_hl(0, "TabLineSel",  { bg = bg })

  local groups = {
    "BufferLineFill", "BufferLineBackground", "BufferLineBuffer",
    "BufferLineBufferVisible",
    "BufferLineTab", "BufferLineTabSelected", "BufferLineTabClose",
    "BufferLineCloseButton", "BufferLineCloseButtonVisible", "BufferLineCloseButtonSelected",
    "BufferLineNumbers", "BufferLineNumbersVisible", "BufferLineNumbersSelected",
    "BufferLineModified", "BufferLineModifiedVisible", "BufferLineModifiedSelected",
    "BufferLineDuplicate", "BufferLineDuplicateVisible", "BufferLineDuplicateSelected",
    "BufferLinePick", "BufferLinePickVisible", "BufferLinePickSelected",
    "BufferLineIndicatorVisible", "BufferLineIndicatorSelected",
    "BufferLineTruncMarker",
    "BufferLineDiagnostic", "BufferLineDiagnosticVisible", "BufferLineDiagnosticSelected",
    "BufferLineHint", "BufferLineHintVisible", "BufferLineHintSelected",
    "BufferLineHintDiagnostic", "BufferLineHintDiagnosticVisible", "BufferLineHintDiagnosticSelected",
    "BufferLineInfo", "BufferLineInfoVisible", "BufferLineInfoSelected",
    "BufferLineInfoDiagnostic", "BufferLineInfoDiagnosticVisible", "BufferLineInfoDiagnosticSelected",
    "BufferLineWarning", "BufferLineWarningVisible", "BufferLineWarningSelected",
    "BufferLineWarningDiagnostic", "BufferLineWarningDiagnosticVisible", "BufferLineWarningDiagnosticSelected",
    "BufferLineError", "BufferLineErrorVisible", "BufferLineErrorSelected",
    "BufferLineErrorDiagnostic", "BufferLineErrorDiagnosticVisible", "BufferLineErrorDiagnosticSelected",
  }
  for _, group in ipairs(groups) do
    local hl = vim.api.nvim_get_hl(0, { name = group })
    hl.bg = bg
    vim.api.nvim_set_hl(0, group, hl)
  end
  -- Inactive tabs: muted gray. BufferLineBackground is the rendered group for
  -- NONE-state buffers; Buffer/BufferVisible are aliases bufferline also sets.
  vim.api.nvim_set_hl(0, "BufferLineBackground",    { bg = bg, fg = 0xB7B5AC })
  vim.api.nvim_set_hl(0, "BufferLineBuffer",        { bg = bg, fg = 0xB7B5AC })
  vim.api.nvim_set_hl(0, "BufferLineBufferVisible", { bg = bg, fg = 0xB7B5AC })

  -- Active tab: let theme handle fg/bold/italic; just align the bg.
  local sel = vim.api.nvim_get_hl(0, { name = "BufferLineBufferSelected" })
  sel.bg = bg
  vim.api.nvim_set_hl(0, "BufferLineBufferSelected", sel)

  vim.api.nvim_set_hl(0, "BufferLineSeparator",         { fg = sep, bg = bg })
  vim.api.nvim_set_hl(0, "BufferLineSeparatorVisible",  { fg = sep, bg = bg })
  vim.api.nvim_set_hl(0, "BufferLineSeparatorSelected", { fg = sep, bg = bg })
  vim.api.nvim_set_hl(0, "BufferLineIndicatorSelected", { fg = bg,  bg = bg })

  -- DevIcon groups: bg only, preserve fg (colour_icons = false already kills tint).
  for name, hl in pairs(vim.api.nvim_get_hl(0, {})) do
    if name:match("^BufferLineDevIcon") then
      hl.bg = bg
      vim.api.nvim_set_hl(0, name, hl)
    end
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    apply_hl_overrides()
    vim.defer_fn(apply_bufferline_bg, 150)
  end,
})
-- Bufferline is VeryLazy so it may not exist at the ColorScheme defer.
-- Run once after VeryLazy so we always win the race.
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function() vim.defer_fn(apply_bufferline_bg, 50) end,
})
apply_hl_overrides()
vim.defer_fn(apply_bufferline_bg, 150)

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

-- Wipeout directory and oil buffers before saving/loading session to prevent window size/layout distortion
vim.api.nvim_create_autocmd("User", {
  pattern = { "PersistenceSavePre", "PersistenceLoadPre" },
  group = vim.api.nvim_create_augroup("PersistenceBufferCleanup", { clear = true }),
  desc = "Wipeout directory and oil buffers before saving or loading session",
  callback = function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) then
        local bufname = vim.api.nvim_buf_get_name(buf)
        if vim.fn.isdirectory(bufname) == 1 or bufname:match("^oil://") then
          pcall(vim.api.nvim_buf_delete, buf, { force = true })
        end
      end
    end
  end,
})

-- Wipeout directory buffers after session load
vim.api.nvim_create_autocmd("User", {
  pattern = "PersistenceLoadPost",
  group = vim.api.nvim_create_augroup("PersistenceDirectoryCleanup", { clear = true }),
  desc = "Clean directory buffers after session load",
  callback = function()
    -- Wipeout directory buffers restored by the session
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) then
        local bufname = vim.api.nvim_buf_get_name(buf)
        if vim.fn.isdirectory(bufname) == 1 then
          pcall(vim.api.nvim_buf_delete, buf, { force = true })
        end
      end
    end
  end,
})

