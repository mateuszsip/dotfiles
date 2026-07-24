-- Window nav from inside Snacks terminals, matching the shifted jkl; layout
-- (see config/keymaps.lua). LazyVim (lazyvim/plugins/util.lua) injects nav_h/j/k/l
-- into Snacks `terminal.win.keys` using the *standard* hjkl directions; Snacks applies
-- these when the terminal window is shown, which shadows the TermOpen maps. Remap them
-- to the physical layout here. Floating terminals pass the key through to the program,
-- matching LazyVim's term_nav behaviour.
local function term_nav(key, dir)
	return function(self)
		if self:is_floating() then
			return "<C-" .. key .. ">"
		end
		vim.schedule(function()
			vim.cmd.wincmd(dir)
		end)
	end
end

local function buf_dir()
	local path = vim.api.nvim_buf_get_name(0)
	if path ~= "" then
		local dir = vim.fn.fnamemodify(path, ":h")
		if vim.fn.isdirectory(dir) == 1 then
			return dir
		end
	end
	return vim.fn.getcwd()
end

return {
	"folke/snacks.nvim",
	keys = {
		-- Disable <C-f> for file search to allow terminal passthrough
		{ "<C-f>", false, mode = { "n", "i", "v" } },
		-- Disable snacks picker git_diff maps; <leader>gd is a diff subgroup (see diffview.lua)
		{ "<leader>gd", false },
		{ "<leader>gD", false },
		-- Diff hunks via snacks picker (replaces the disabled top-level maps above)
		{
			"<leader>gdd",
			function()
				Snacks.picker.git_diff()
			end,
			desc = "Diff Hunks (working tree)",
		},
		{
			"<leader>gdD",
			function()
				Snacks.picker.git_diff({ base = "origin", group = true })
			end,
			desc = "Diff Hunks (origin)",
		},
		{
			"<leader>ftq",
			function()
				Snacks.terminal.toggle(
					nil,
					{ count = 1, cwd = vim.fn.getcwd(), win = { position = "bottom", height = 0.3, stack = true } }
				)
			end,
			desc = "Terminal 1",
		},
		{
			"<leader>ftw",
			function()
				Snacks.terminal.toggle(
					nil,
					{ count = 2, cwd = vim.fn.getcwd(), win = { position = "bottom", height = 0.3, stack = true } }
				)
			end,
			desc = "Terminal 2",
		},
		{
			"<leader>fte",
			function()
				Snacks.terminal.toggle(
					nil,
					{ count = 3, cwd = vim.fn.getcwd(), win = { position = "bottom", height = 0.3, stack = true } }
				)
			end,
			desc = "Terminal 3",
		},
		{
			"<leader>fta",
			function()
				Snacks.terminal.toggle(
					nil,
					{ count = 4, cwd = vim.fn.getcwd(), win = { position = "bottom", height = 0.3, stack = true } }
				)
			end,
			desc = "Terminal 4",
		},
		{
			"<leader>fts",
			function()
				Snacks.terminal.toggle(
					nil,
					{ count = 5, cwd = vim.fn.getcwd(), win = { position = "bottom", height = 0.3, stack = true } }
				)
			end,
			desc = "Terminal 5",
		},
		{
			"<leader>ftd",
			function()
				Snacks.terminal.toggle(
					nil,
					{ count = 6, cwd = vim.fn.getcwd(), win = { position = "bottom", height = 0.3, stack = true } }
				)
			end,
			desc = "Terminal 6",
		},
		{
			"<leader>fTq",
			function()
				Snacks.terminal.toggle(
					nil,
					{ count = 1, cwd = buf_dir(), win = { position = "bottom", height = 0.3, stack = true } }
				)
			end,
			desc = "Terminal 1 (buf dir)",
		},
		{
			"<leader>fTw",
			function()
				Snacks.terminal.toggle(
					nil,
					{ count = 2, cwd = buf_dir(), win = { position = "bottom", height = 0.3, stack = true } }
				)
			end,
			desc = "Terminal 2 (buf dir)",
		},
		{
			"<leader>fTe",
			function()
				Snacks.terminal.toggle(
					nil,
					{ count = 3, cwd = buf_dir(), win = { position = "bottom", height = 0.3, stack = true } }
				)
			end,
			desc = "Terminal 3 (buf dir)",
		},
		{
			"<leader>fTa",
			function()
				Snacks.terminal.toggle(
					nil,
					{ count = 4, cwd = buf_dir(), win = { position = "bottom", height = 0.3, stack = true } }
				)
			end,
			desc = "Terminal 4 (buf dir)",
		},
		{
			"<leader>fTs",
			function()
				Snacks.terminal.toggle(
					nil,
					{ count = 5, cwd = buf_dir(), win = { position = "bottom", height = 0.3, stack = true } }
				)
			end,
			desc = "Terminal 5 (buf dir)",
		},
		{
			"<leader>fTd",
			function()
				Snacks.terminal.toggle(
					nil,
					{ count = 6, cwd = buf_dir(), win = { position = "bottom", height = 0.3, stack = true } }
				)
			end,
			desc = "Terminal 6 (buf dir)",
		},
		{
			"<leader>ftt",
			function()
				local terms = Snacks.terminal.list()
				local shown = vim.tbl_filter(function(t)
					return t:win_valid()
				end, terms)
				if #shown > 0 then
					for _, t in ipairs(shown) do
						t:hide()
					end
				elseif #terms > 0 then
					for _, t in ipairs(terms) do
						t:show()
					end
				else
					Snacks.terminal.toggle(
						nil,
						{ count = 1, cwd = vim.fn.getcwd(), win = { position = "bottom", height = 0.3, stack = true } }
					)
				end
			end,
			desc = "Toggle All Terminals",
		},
		{
			"<leader>fT",
			function()
				local terms = Snacks.terminal.list()
				local shown = vim.tbl_filter(function(t)
					return t:win_valid()
				end, terms)
				if #shown > 0 then
					for _, t in ipairs(shown) do
						t:hide()
					end
				elseif #terms > 0 then
					for _, t in ipairs(terms) do
						t:show()
					end
				else
					Snacks.terminal.toggle(
						nil,
						{ count = 1, cwd = buf_dir(), win = { position = "bottom", height = 0.3, stack = true } }
					)
				end
			end,
			desc = "Toggle All Terminals",
		},
	},
	opts = {
		terminal = {
			win = {
				keys = {
					-- Match the shifted jkl; window-nav layout (see config/keymaps.lua):
					-- C-j=left, C-k=down, C-l=up, C-;=right. C-h exits terminal mode
					-- (handled by the TermOpen map), so disable LazyVim's nav_h.
					nav_h = false,
					nav_j = { "<C-j>", term_nav("j", "h"), expr = true, mode = "t", desc = "Go to Left Window" },
					nav_k = { "<C-k>", term_nav("k", "j"), expr = true, mode = "t", desc = "Go to Lower Window" },
					nav_l = { "<C-l>", term_nav("l", "k"), expr = true, mode = "t", desc = "Go to Upper Window" },
					nav_semicolon = {
						"<C-;>",
						term_nav(";", "l"),
						expr = true,
						mode = "t",
						desc = "Go to Right Window",
					},
				},
			},
		},
		scroll = {
			enabled = true, -- Disable scrolling animations
		},
		image = {
			enabled = true,
			doc = {
				-- Don't render images inline in the buffer. Instead show the image
				-- under the cursor in a floating window (snacks' built-in hover mode,
				-- triggered automatically on CursorMoved). See snacks image/doc.lua.
				inline = false,
				float = true,
			},
		},
		picker = {
			sources = {
				projects = {
					dev = { "~/dev/work", "~/Work/" },
					projects = {
						"~/.local/share/chezmoi",
						"~/.config/nvim",
						"~/.config/hypr",
					},
				},
				marks = {
					actions = {
						delete_mark = function(picker, item)
							if item then
								vim.cmd("delmarks " .. item.label)
								picker:find()
							end
						end,
					},
					win = {
						input = {
							keys = {
								["<C-d>"] = { "delete_mark", mode = { "i", "n" } },
							},
						},
					},
				},
			},
			win = {
				input = {
					keys = {
						-- Override defaults so the physical jkl; layout stays consistent in pickers.
						-- Snacks binds `j`=list_down and `k`=list_up as buffer-local maps
						-- (picker/config/defaults.lua), which shadow this config's global jkl; remap,
						-- so physical `k` (your "Down" key) would move UP with stock Snacks. Swap to
						-- match the physical layout in normal mode; while typing, use the arrow keys
						-- (<c-j>/<c-k>/<c-l> are reserved for window navigation, see keymaps.lua).
						["j"] = false,
						[";"] = false,
						["k"] = "list_down",
						["l"] = "list_up",
						["<PageDown>"] = { "list_scroll_down", mode = { "i", "n" } },
						["<PageUp>"] = { "list_scroll_up", mode = { "i", "n" } },
						["<Tab>"] = { "focus_preview", mode = { "i", "n" } },
						["<S-Tab>"] = { "focus_list", mode = { "i", "n" } },
						["<C-Space>"] = { "select_and_next", mode = { "i", "n" } },
						["<C-S-Space>"] = { "select_and_prev", mode = { "i", "n" } },
						["<C-S-q>"] = { "loclist", mode = { "i", "n" } },
						["<A-w>"] = "none",
					},
				},
				list = {
					keys = {
						-- Match the physical jkl; layout (see input window comment above).
						["j"] = false,
						[";"] = false,
						["k"] = "list_down",
						["l"] = "list_up",
						["<Tab>"] = "focus_preview",
						["<S-Tab>"] = "focus_list",
						["<C-Space>"] = { "select_and_next", mode = { "i", "n" } },
						["<C-S-Space>"] = { "select_and_prev", mode = { "i", "n" } },
						["<C-S-q>"] = { "loclist", mode = { "i", "n" } },
						["<A-w>"] = "none",
					},
				},
				preview = {
					keys = {
						["<Tab>"] = "focus_list",
						["<S-Tab>"] = "focus_input",
						["<M-q>"] = { "loclist", mode = { "i", "n" } },
						["<A-w>"] = "none",
					},
				},
			},
		},
	},
}
