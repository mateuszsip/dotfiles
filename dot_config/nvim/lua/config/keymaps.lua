-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
-- lua/config/keymaps.lua
local map = vim.keymap.set

-- Root detection: drop "lsp" from LazyVim defaults so root is always the
-- git toplevel (or "lua" project root), never an LSP workspace subdir.
vim.g.root_spec = { { ".git", "lua" }, "cwd" }

-- Fix LazyVim root detection for URI-scheme buffers (oil://, term://, ...).
-- M.realpath does `fs_realpath(path) or path`, so for an `oil:///path` URI it
-- keeps the (invalid) URI and M.norm collapses "//" -> "/", yielding `oil:/path`.
-- That non-nil mangled path feeds M.detectors.pattern, the cwd fallback never
-- triggers, and vim.fs.find upward from the invalid path finds nothing -> the
-- (.git/.lua) detector returns empty and root falls through to `cwd`.
-- Treat scheme buffers as having no real path so detection falls back to cwd.
do
  local root = require("lazyvim.util.root")
  if not root._bufpath_patched then
    root._bufpath_patched = true
    root.bufpath = function(b)
      local name = vim.api.nvim_buf_get_name(b)
      if name == "" or name:find("://") then
        return nil
      end
      return root.realpath(name)
    end
  end
end

-- Note: <C-f> is disabled in snacks config (lua/plugins/snacks-animated-scrolling-off.lua)
-- Terminal passthrough is handled in the TermOpen autocmd below

-- Remap h to j, j to k, k to l, l to ; (example)
map({ "n", "x" }, "j", "h", { desc = "Left" })
map({ "n", "x" }, "k", "j", { desc = "Down" })
map({ "n", "x" }, "l", "k", { desc = "Up" })
map({ "n", "x" }, ";", "l", { desc = "Right" })
map({ "n", "x", "o" }, "h", function()
  require("flash.plugins.char").jump(";")
end, { desc = "Repeat f/t forward" })
map({ "n", "x" }, "J", "^", { desc = "Start of line" })
map({ "n", "x" }, ":", "$", { desc = "End of line" })
map({ "n", "x" }, ",", ":", { desc = "Command mode" })

map({ "n", "x" }, "k", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "l", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

map("n", "<C-j>", "<C-w>h", { desc = "Go to Left Window", remap = true })
map("n", "<C-k>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
map("n", "<C-l>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
map("n", "<C-;>", "<C-w>l", { desc = "Go to Right Window", remap = true })

vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    local opts = { buffer = 0 }
    vim.keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>h", vim.tbl_extend("force", opts, { desc = "Go to Left Window" }))
    vim.keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>j", vim.tbl_extend("force", opts, { desc = "Go to Lower Window" }))
    vim.keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>k", vim.tbl_extend("force", opts, { desc = "Go to Upper Window" }))
    vim.keymap.set("t", "<C-;>", "<C-\\><C-n><C-w>l", vim.tbl_extend("force", opts, { desc = "Go to Right Window" }))
    vim.keymap.set("t", "<C-h>", "<C-\\><C-n>", vim.tbl_extend("force", opts, { desc = "Exit Terminal Mode" }))
    vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", vim.tbl_extend("force", opts, { desc = "Exit Terminal Mode" }))
    -- Pass <C-f> through to terminal (for opencode)
    vim.keymap.set("t", "<C-f>", "<C-f>", vim.tbl_extend("force", opts, { desc = "Pass to terminal" }))
  end,
})

map("n", "<C-Up>", "<cmd>resize +5<cr>", { desc = "Increase Window Height" })
map("n", "<C-Down>", "<cmd>resize -5<cr>", { desc = "Decrease Window Height" })
map("n", "<C-Left>", "<cmd>vertical resize -5<cr>", { desc = "Decrease Window Width" })
map("n", "<C-Right>", "<cmd>vertical resize +5<cr>", { desc = "Increase Window Width" })

map("n", "<A-k>", function()
  if vim.wo.diff then
    vim.cmd("normal! " .. vim.v.count1 .. "]c")
  else
    vim.cmd("move .+" .. vim.v.count1)
    vim.cmd("normal! ==")
  end
end, { desc = "Next Diff Hunk / Move Line Down" })

map("n", "<A-l>", function()
  if vim.wo.diff then
    vim.cmd("normal! " .. vim.v.count1 .. "[c")
  else
    vim.cmd("move .-" .. (vim.v.count1 + 1))
    vim.cmd("normal! ==")
  end
end, { desc = "Prev Diff Hunk / Move Line Up" })
map("i", "<A-k>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<A-l>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<A-k>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("v", "<A-l>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

map("n", "<A-S-j>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "<A-S-;>", "<cmd>bnext<cr>", { desc = "Next Buffer" })

map("n", "<A-j>", "<cmd>cprev<cr>", { desc = "Previous Quickfix" })
map("n", "<A-;>", "<cmd>cnext<cr>", { desc = "Next Quickfix" })

map("n", "<leader>ff", LazyVim.pick("files", { root = false }), { desc = "Find Files (cwd)" })
map("n", "<leader>fF", LazyVim.pick("files"), { desc = "Find Files (Root Dir)" })
map("n", "<leader>fh", function()
  Snacks.picker.files({ cwd = vim.fn.expand("~") })
end, { desc = "Find Files (home)" })
-- Find Directories picker (chdir + Neotree focus on confirm)
local function find_dirs(cwd)
  Snacks.picker({
    title = "Find Directories",
    cwd = cwd,
    format = "file",
    finder = function(_, ctx)
      return require("snacks.picker.source.proc").proc(
        ctx:opts({
          cmd = "fd",
          args = { "--type", "d", "--hidden", "--exclude", ".git", "." },
          transform = function(item)
            item.file = item.text
            item.dir = true
          end,
        }),
        ctx
      )
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        local dir = cwd .. "/" .. item.file
        require("oil").open_float(dir, { preview = { vertical = true } })
      end
    end,
  })
end
map("n", "<leader>fd", function()
  find_dirs(vim.fn.getcwd())
end, { desc = "Find Directories (cwd)" })
map("n", "<leader>fD", function()
  find_dirs(LazyVim.root.get())
end, { desc = "Find Directories (Root Dir)" })
map("n", "<leader>fH", function()
  find_dirs(vim.fn.expand("~"))
end, { desc = "Find Directories (home)" })
map("n", "<leader>f.", function()
  local dir = vim.fn.expand("%:p:h")
  if vim.fn.isdirectory(dir) == 1 then
    vim.fn.chdir(dir)
    vim.notify("cd " .. dir)
  end
end, { desc = "cd to buf dir" })
map("n", "<leader>f-", function()
  vim.cmd("cd -")
  vim.notify("cd " .. vim.fn.getcwd())
end, { desc = "cd back (previous dir)" })
map("n", "<leader>f~", function()
  vim.fn.chdir(vim.fn.expand("~"))
  vim.notify("cd " .. vim.fn.getcwd())
end, { desc = "cd to home dir" })
map("n", "<leader>f_", function() require("utils.cwd").pick() end, { desc = "CWD History" })
map("n", "<leader>fw", function()
  Snacks.picker.files({ root = false, pattern = vim.fn.expand("<cword>") })
end, { desc = "Find Files (word, cwd)" })
map("n", "<leader>fW", function()
  Snacks.picker.files({ pattern = vim.fn.expand("<cword>") })
end, { desc = "Find Files (word, Root Dir)" })
map("n", "<leader>sf", LazyVim.pick("files", { root = false }), { desc = "Find Files (cwd)" })
map("n", "<leader>sF", LazyVim.pick("files"), { desc = "Find Files (Root Dir)" })
map("n", "<leader>sg", LazyVim.pick("live_grep", { root = false }), { desc = "Grep (cwd)" })
map("n", "<leader>sG", LazyVim.pick("live_grep"), { desc = "Grep (Root Dir)" })
map("n", "<leader>s.", function()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" or vim.fn.filereadable(file) == 0 then
    return Snacks.notify.warn("Buffer has no readable file")
  end
  Snacks.picker.grep({ dirs = { file }, title = "Grep (current file)" })
end, { desc = "Grep (current file)" })
map({ "n", "x" }, "<leader>sw", function()
  Snacks.picker.grep_word({ root = false })
end, { desc = "Grep Word (cwd)" })
map({ "n", "x" }, "<leader>sW", function()
  Snacks.picker.grep_word()
end, { desc = "Grep Word (Root Dir)" })

map("n", "<leader>ss", LazyVim.pick("lsp_document_symbols"), { desc = "Document Symbols" })
map("n", "<leader>sS", LazyVim.pick("lsp_workspace_symbols"), { desc = "Workspace Symbols" })

map("n", "<leader>be", function()
  Snacks.picker.buffers()
end, { desc = "Buffer Picker" })

map("n", "<leader><space>", LazyVim.pick("files", { root = false }), { desc = "Find Files (cwd)" })
map("n", "<leader>/", LazyVim.pick("grep", { root = false }), { desc = "Grep (cwd)" })

map("n", "<leader>CA", function()
  Snacks.terminal({ "chezmoi", "apply" }, { auto_close = true })
end, { desc = "Chezmoi Apply All" })

-- Override LazyVim's terminal labels
map("n", "<leader>ft", function()
  Snacks.terminal(nil, { cwd = vim.fn.getcwd() })
end, { desc = "Terminal (cwd)" })
map("n", "<leader>fT", function()
  local path = vim.api.nvim_buf_get_name(0)
  local dir = path ~= "" and vim.fn.fnamemodify(path, ":h") or nil
  if dir and vim.fn.isdirectory(dir) ~= 1 then
    dir = nil
  end
  Snacks.terminal(nil, { cwd = dir or vim.fn.getcwd() })
end, { desc = "Terminal (buf dir)" })

-- Toggle diagnostic virtual text (inline messages); <leader>ud toggles all diagnostics
local _vt_on = { spacing = 4, source = "if_many", prefix = "●" }
map("n", "<leader>uv", function()
  local off = vim.diagnostic.config().virtual_text == false
  vim.diagnostic.config({ virtual_text = off and _vt_on or false })
end, { desc = "Toggle Virtual Text" })

-- Fold keymaps (overrides movement mappings above; require() is lazy so safe before origami loads)
map("n", "j", function()
  require("origami").h()
end, { desc = "Left / fold" })
map("n", ";", function()
  require("origami").l()
end, { desc = "Right / unfold" })

map("n", "ZZ", "<cmd>wqall<cr>", { desc = "Save all and quit" })
map("n", "Zz", "<cmd>qall<cr>", { desc = "Quit all" })

-- Copy relative path of current buffer
map("n", "<leader>yr", function()
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" or name:match("://") then
    return Snacks.notify.warn("Buffer has no readable file")
  end
  if vim.fn.filereadable(name) == 0 and vim.fn.isdirectory(name) == 0 then
    return Snacks.notify.warn("Buffer has no readable file")
  end
  require("utils.path").copy_relative(name, vim.uv.cwd())
end, { desc = "Copy relative path (cwd)" })
map("n", "<leader>yR", function()
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" or name:match("://") then
    return Snacks.notify.warn("Buffer has no readable file")
  end
  if vim.fn.filereadable(name) == 0 and vim.fn.isdirectory(name) == 0 then
    return Snacks.notify.warn("Buffer has no readable file")
  end
  require("utils.path").copy_relative(name, LazyVim.root())
end, { desc = "Copy relative path (root)" })
