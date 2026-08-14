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

-- Toggle terminal `count` in a bottom split rooted at the dir `cwd_fn` returns.
-- `cwd_fn` is called at keypress time so the cwd follows the current buffer.
local function term_toggle(count, cwd_fn)
	return function()
		Snacks.terminal.toggle(
			nil,
			{ count = count, cwd = cwd_fn(), win = { position = "bottom", height = 0.3, stack = true } }
		)
	end
end

-- Hide all shown terminals, show all hidden ones, or open terminal 1 if none exist.
local function term_toggle_all(cwd_fn)
	return function()
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
			term_toggle(1, cwd_fn)()
		end
	end
end

-- Numbered terminal keymaps: <leader>ft{q,w,e,a,s,d} = terminals 1-6 (cwd),
-- <leader>fT{q,w,e,a,s,d} = terminals 1-6 (buf dir).
local term_keys = { "q", "w", "e", "a", "s", "d" }
local keys = {
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
	{ "<leader>ftt", term_toggle_all(vim.fn.getcwd), desc = "Toggle All Terminals" },
	{ "<leader>fT", term_toggle_all(buf_dir), desc = "Toggle All Terminals (buf dir)" },
}
for i, key in ipairs(term_keys) do
	table.insert(keys, { "<leader>ft" .. key, term_toggle(i, vim.fn.getcwd), desc = "Terminal " .. i })
	table.insert(keys, { "<leader>fT" .. key, term_toggle(i, buf_dir), desc = "Terminal " .. i .. " (buf dir)" })
end

return {
	"folke/snacks.nvim",
	keys = keys,
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
			enabled = false, -- Disable scrolling animations (neoscroll.nvim handles smooth scroll)
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
		styles = {
			-- The image hover float defaults to relative="cursor" (row=1, col=1), so
			-- tall images clip against the screen edge when the cursor is low — the
			-- whole image isn't shown. Anchor to the editor and center it instead;
			-- snacks centers a float when row/col are falsy (see snacks/win.lua pos()),
			-- and treats relative="editor" specially when sizing (image/placement.lua).
			snacks_image = {
				relative = "editor",
				row = false,
				col = false,
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
