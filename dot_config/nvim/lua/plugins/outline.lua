return {
	{
		"hedyhli/outline.nvim",
		lazy = true,
		cmd = { "Outline", "OutlineOpen" },
		-- Override LazyVimTrouble's `<leader>cs` (Trouble symbols toggle) with outline.nvim.
		-- The `<leader>cS` (Trouble lsp references/definitions) binding is left intact.
		keys = {
			{ "<leader>cs", "<cmd>Outline<CR>", desc = "Toggle Outline" },
			{ "<leader>cS", "<cmd>OutlineOpen<CR>", desc = "Open Outline" },
		},
		opts = {
			outline_window = {
				position = "right",
				width = 25,
				relative_width = true,
				auto_close = false,
				auto_jump = false,
				show_numbers = false,
				show_relative_numbers = false,
				show_cursorline = true,
				hide_cursor = false,
				focus_on_open = false,
				center_on_jump = true,
			},
			outline_items = {
				show_symbol_details = true,
				show_symbol_lineno = true,
				highlight_hovered_item = true,
				auto_set_cursor = true,
			},
			symbol_folding = {
				autofold_depth = 1,
				markers = { "", "" },
			},
			preview_window = {
				auto_preview = true,
				open_hover_on_preview = true,
				border = "rounded",
				winblend = 0,
				live = false,
			},
			keymaps = {
				show_help = "?",
				close = { "<Esc>", "q" },
				goto_location = "<CR>",
				peek_location = "o",
				restore_location = "<C-g>",
				hover_symbol = "<C-space>",
				toggle_preview = "K",
				rename_symbol = "r",
				code_actions = "a",
				-- `fold`/`unfold` default to h/l, which collide with this config's
				-- jkl; navigation layout (j=left k=down l=up ;=right). Disable them;
				-- use <Tab> (fold_toggle) for collapsing nodes instead.
				fold = {},
				unfold = {},
				fold_toggle = "<Tab>",
				fold_toggle_all = "<S-Tab>",
				fold_all = "W",
				unfold_all = "E",
				fold_reset = "R",
				-- Disabled so <C-j>/<C-k>/<C-l>/<C-;> keep navigating windows
				-- even when the cursor is inside the outline window.
				down_and_jump = {},
				up_and_jump = {},
			},
			providers = {
				priority = { "lsp", "markdown", "norg", "man" },
				lsp = { blacklist_clients = {} },
				markdown = { filetypes = { "markdown" } },
			},
		},
		-- outline.nvim sets buffer-local keymaps for its actions (with noremap=true),
		-- so they shadow the global jkl; navigation layout in the outline window.
		-- Re-apply the layout explicitly as buffer-local maps whenever an outline
		-- buffer is created (filetype 'Outline'). This runs *after* outline's own
		-- setup_keymaps (which no longer touches h/l/\c-j/\c-k thanks to the empty
		-- tables above), so these survive.
		config = function(_, opts)
			require("outline").setup(opts)
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "Outline",
				callback = function(args)
					local function nav(lhs, rhs)
						vim.keymap.set("n", lhs, rhs, { buffer = args.buf, remap = false, silent = true })
					end
					nav("j", "h") -- left
					nav("k", "j") -- down
					nav("l", "k") -- up
					nav(";", "l") -- right
				end,
			})
		end,
	},
}
