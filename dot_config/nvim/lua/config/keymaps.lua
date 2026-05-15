-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
-- lua/config/keymaps.lua
local map = vim.keymap.set

-- Note: <C-f> is disabled in snacks config (lua/plugins/snacks-animated-scrolling-off.lua)
-- Terminal passthrough is handled in the TermOpen autocmd below

-- Remap h to j, j to k, k to l, l to ; (example)
map({ "n", "x" }, "j", "h", { desc = "Left" })
map({ "n", "x" }, "k", "j", { desc = "Down" })
map({ "n", "x" }, "l", "k", { desc = "Up" })
map({ "n", "x" }, ";", "l", { desc = "Right" })
map({ "n", "x", "o" }, "h", function() require("flash.plugins.char").jump(";") end, { desc = "Repeat f/t forward" })

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

map("n", "<A-k>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
map("n", "<A-l>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
map("i", "<A-k>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<A-l>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<A-k>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("v", "<A-l>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

map("n", "<A-S-j>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "<A-S-;>", "<cmd>bnext<cr>", { desc = "Next Buffer" })

map("n", "<leader>ff", LazyVim.pick("files", { root = false }), { desc = "Find Files (cwd)" })
map("n", "<leader>fh", function() Snacks.picker.files({ cwd = vim.fn.expand("~") }) end, { desc = "Find Files (home)" })
map("n", "<leader>fd", function()
  Snacks.picker({
    title = "Find Directories",
    cwd = vim.fn.expand("~"),
    format = "file",
    finder = function(opts, ctx)
      return require("snacks.picker.source.proc").proc(ctx:opts({
        cmd = "fd",
        args = { "--type", "d", "--hidden", "--exclude", ".git", "." },
        transform = function(item)
          item.file = item.text
          item.dir = true
        end,
      }), ctx)
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        vim.schedule(function()
          local dir = vim.fn.expand("~") .. "/" .. item.file
          vim.fn.chdir(dir)
          vim.cmd("Neotree focus dir=" .. dir)
        end)
      end
    end,
  })
end, { desc = "Find Directories (home)" })
map("n", "<leader>fF", LazyVim.pick("files"), { desc = "Find Files (Root Dir)" })
map("n", "<leader>fw", function() Snacks.picker.files({ root = false, pattern = vim.fn.expand("<cword>") }) end, { desc = "Find Files (word, cwd)" })
map("n", "<leader>fW", function() Snacks.picker.files({ pattern = vim.fn.expand("<cword>") }) end, { desc = "Find Files (word, Root Dir)" })
map("n", "<leader>sf", LazyVim.pick("files", { root = false }), { desc = "Find Files (cwd)" })
map("n", "<leader>sF", LazyVim.pick("files"), { desc = "Find Files (Root Dir)" })
map("n", "<leader>sg", LazyVim.pick("live_grep", { root = false }), { desc = "Grep (cwd)" })
map("n", "<leader>sG", LazyVim.pick("live_grep"), { desc = "Grep (Root Dir)" })
map({ "n", "x" }, "<leader>sw", function() Snacks.picker.grep_word({ root = false }) end, { desc = "Grep Word (cwd)" })
map({ "n", "x" }, "<leader>sW", function() Snacks.picker.grep_word() end, { desc = "Grep Word (Root Dir)" })

map("n", "<leader>ss", LazyVim.pick("lsp_document_symbols"), { desc = "Document Symbols" })
map("n", "<leader>sS", LazyVim.pick("lsp_workspace_symbols"), { desc = "Workspace Symbols" })

map("n", "<leader>be", function() Snacks.picker.buffers() end, { desc = "Buffer Picker" })

map("n", "<leader><space>", LazyVim.pick("files", { root = false }), { desc = "Find Files (cwd)" })
map("n", "<leader>/", LazyVim.pick("grep", { root = false }), { desc = "Grep (cwd)" })

map("n", "<leader>CA", function()
  Snacks.terminal({ "chezmoi", "apply" }, { auto_close = true })
end, { desc = "Chezmoi Apply All" })

-- Toggle diagnostic virtual text (inline messages); <leader>ud toggles all diagnostics
local _vt_on = { spacing = 4, source = "if_many", prefix = "●" }
map("n", "<leader>uv", function()
  local off = vim.diagnostic.config().virtual_text == false
  vim.diagnostic.config({ virtual_text = off and _vt_on or false })
end, { desc = "Toggle Virtual Text" })

-- Fold keymaps (overrides movement mappings above; require() is lazy so safe before origami loads)
map("n", "j", function() require("origami").h() end, { desc = "Left / fold" })
map("n", ";", function() require("origami").l() end, { desc = "Right / unfold" })
