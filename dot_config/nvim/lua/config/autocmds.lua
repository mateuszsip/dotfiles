-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Thin window separators: flexoki sets fg=bg on WinSeparator making a solid filled block.
-- Override to bg=NONE so only the thin │ glyph is visible as a subtle line.
local function apply_hl_overrides()
  -- Thin window separators (flexoki sets fg=bg, making a solid block)
  vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#CECDC3", bg = "NONE" })
  -- Code blocks: subtle warm tint instead of the prominent grey
  vim.api.nvim_set_hl(0, "RenderMarkdownCode", { bg = "#F2F0E5" })
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
    "BufferLineBufferVisible", "BufferLineBufferSelected",
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
  vim.api.nvim_set_hl(0, "BufferLineSeparator",         { fg = sep, bg = bg })
  vim.api.nvim_set_hl(0, "BufferLineSeparatorVisible",  { fg = sep, bg = bg })
  vim.api.nvim_set_hl(0, "BufferLineSeparatorSelected", { fg = sep, bg = bg })

  -- DevIcon groups are dynamically named per filetype; sweep all of them.
  for name, hl in pairs(vim.api.nvim_get_hl(0, {})) do
    if name:match("^BufferLineDevIcon") then
      hl.bg = bg
      vim.api.nvim_set_hl(0, name, hl)
    end
  end
end

local function apply_lualine_bg()
  local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
  local bg = normal.bg or 0xFFFCF0
  local modes = { "normal", "insert", "visual", "replace", "command", "inactive" }
  for _, mode in ipairs(modes) do
    for _, section in ipairs({ "b", "c", "x", "y", "z" }) do
      local name = "lualine_" .. section .. "_" .. mode
      local hl = vim.api.nvim_get_hl(0, { name = name })
      if next(hl) then
        hl.bg = bg
        vim.api.nvim_set_hl(0, name, hl)
      end
    end
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    apply_hl_overrides()
    vim.defer_fn(apply_bufferline_bg, 50)
    vim.defer_fn(apply_lualine_bg, 50)
  end,
})
apply_hl_overrides()
vim.defer_fn(apply_bufferline_bg, 50)
vim.defer_fn(apply_lualine_bg, 50)

-- Markdown editing helpers: wrap word (normal) or selection (visual) with syntax markers
-- Keys are fed as one sequence so mode transitions happen naturally:
-- ciw/c enters insert mode (storing yanked text in "), <C-r>" pastes it back wrapped.
local function md_wrap(open, close)
  return function()
    local mode   = vim.fn.mode()
    local esc    = vim.api.nvim_replace_termcodes("<Esc>",   true, false, true)
    local cr_reg = vim.api.nvim_replace_termcodes('<C-r>"',  true, false, true)
    local prefix = (mode == "v" or mode == "V" or mode == "\22") and "c" or "ciw"
    vim.api.nvim_feedkeys(prefix .. open .. cr_reg .. close .. esc, "n", false)
  end
end

-- Wrap word/selection as [text]( and leave cursor in insert mode to type URL
local function md_link()
  local mode   = vim.fn.mode()
  local cr_reg = vim.api.nvim_replace_termcodes('<C-r>"', true, false, true)
  local left   = vim.api.nvim_replace_termcodes("<Left>", true, false, true)
  local prefix = (mode == "v" or mode == "V" or mode == "\22") and "c" or "ciw"
  vim.api.nvim_feedkeys(prefix .. "[" .. cr_reg .. "]()" .. left, "n", false)
end

-- Remove markdown markers immediately surrounding the word under the cursor
local function md_unwrap()
  local pos  = vim.api.nvim_win_get_cursor(0)
  local col  = pos[2]  -- 0-indexed
  local line = vim.api.nvim_get_current_line()

  -- Locate word boundaries (1-indexed)
  local ws, we = col + 1, col + 1
  while ws > 1    and line:sub(ws - 1, ws - 1):match("%w") do ws = ws - 1 end
  while we < #line and line:sub(we + 1, we + 1):match("%w") do we = we + 1 end

  local before, after = line:sub(1, ws - 1), line:sub(we + 1)

  -- Check longest markers first so ** isn't stripped as two * matches
  for _, m in ipairs({ "***", "~~", "**", "==", "*", "`" }) do
    local n = #m
    if before:sub(-n) == m and after:sub(1, n) == m then
      vim.api.nvim_set_current_line(before:sub(1, -n - 1) .. line:sub(ws, we) .. after:sub(n + 1))
      vim.api.nvim_win_set_cursor(0, { pos[1], math.max(0, col - n) })
      return
    end
  end
end

-- Set or remove heading level on the current line (idempotent)
local function md_heading(level)
  return function()
    local line = vim.api.nvim_get_current_line()
    local content = line:gsub("^#+%s*", "")
    vim.api.nvim_set_current_line(level == 0 and content or (string.rep("#", level) .. " " .. content))
  end
end

-- Toggle blockquote prefix on the current line
local function md_blockquote()
  local line = vim.api.nvim_get_current_line()
  vim.api.nvim_set_current_line(line:match("^> ") and line:sub(3) or ("> " .. line))
end

-- Wrap visual selection in triple-backtick fences; cursor lands after opening ``` to type language
local function md_code_fence()
  local start_line = math.min(vim.fn.line("."), vim.fn.line("v"))
  local end_line   = math.max(vim.fn.line("."), vim.fn.line("v"))
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  local new_lines = { "```" }
  vim.list_extend(new_lines, lines)
  table.insert(new_lines, "```")
  vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, new_lines)
  vim.api.nvim_win_set_cursor(0, { start_line, 3 })
  vim.cmd("startinsert!")
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    local map = vim.keymap.set
    local o = { buffer = true }
    -- Inline styles
    map("n",          "<leader>mx", md_unwrap,              vim.tbl_extend("force", o, { desc = "Markdown: Remove markers" }))
    map({ "n", "v" }, "<leader>mb", md_wrap("**", "**"),   vim.tbl_extend("force", o, { desc = "Markdown: Bold" }))
    map({ "n", "v" }, "<leader>mi", md_wrap("*", "*"),     vim.tbl_extend("force", o, { desc = "Markdown: Italic" }))
    map({ "n", "v" }, "<leader>mc", md_wrap("`", "`"),     vim.tbl_extend("force", o, { desc = "Markdown: Inline code" }))
    map({ "n", "v" }, "<leader>ms", md_wrap("~~", "~~"),   vim.tbl_extend("force", o, { desc = "Markdown: Strikethrough" }))
    -- Link
    map({ "n", "v" }, "<leader>ml", md_link,               vim.tbl_extend("force", o, { desc = "Markdown: Link" }))
    -- Headings (0 = remove)
    for i = 0, 6 do
      local desc = i == 0 and "Markdown: Remove heading" or ("Markdown: H" .. i)
      map("n", "<leader>m" .. i, md_heading(i), vim.tbl_extend("force", o, { desc = desc }))
    end
    -- Blockquote toggle
    map("n", "<leader>mq", md_blockquote,                  vim.tbl_extend("force", o, { desc = "Markdown: Blockquote toggle" }))
    -- Code fence (visual only)
    map("v", "<leader>mC", md_code_fence,                  vim.tbl_extend("force", o, { desc = "Markdown: Code fence" }))
  end,
})

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
      vim.cmd("cclose")
      require("trouble").open({ mode = "quickfix", focus = true, open_folds = false })
    end)
  end,
})
