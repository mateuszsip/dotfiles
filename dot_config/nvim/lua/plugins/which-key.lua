return {
	"folke/which-key.nvim",
	opts = {
		-- Match octo.nvim's built-in rule: atlas keymaps get the `git` filetype icon.
		icons = {
			rules = {
				{ plugin = "atlas.nvim", cat = "filetype", name = "git" },
			},
		},
		spec = {
			{ "<leader>C", group = "chezmoi" },
			{ "<leader>o", group = "obsidian" },
			{ "<leader>ow", group = "workspace" },
			{ "<leader>m", group = "markdown" },
			{ "<leader>fe", group = "Explorer Oil" },
			{ "<leader>y", group = "yank" },
			{ "<leader>gd", group = "diff" },
			{ "<leader>P", group = "present" },
		},
	},
}
