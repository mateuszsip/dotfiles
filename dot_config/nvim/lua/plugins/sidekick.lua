return {
	"folke/sidekick.nvim",
	keys = {
		{
			"<leader>ac",
			function()
				require("sidekick.cli").toggle({ name = "claude", focus = true })
			end,
			desc = "Sidekick Toggle Claude",
		},
		{
			"<leader>ao",
			function()
				require("sidekick.cli").toggle({ name = "opencode2", focus = true })
			end,
			desc = "Sidekick Toggle OpenCode 2",
		},
		{
			"<leader>ag",
			function()
				require("sidekick.cli").toggle({ name = "antigravity", focus = true })
			end,
			desc = "Sidekick Toggle Antigravity",
		},
		{
			"<leader>ap",
			function()
				require("sidekick.cli").toggle({ name = "pi", focus = true })
			end,
			desc = "Sidekick Toggle Pi",
		},
		{
			"<leader>aP",
			function()
				require("sidekick.cli").prompt()
			end,
			mode = { "n", "x" },
			desc = "Sidekick Select Prompt",
		},
		{
			"<leader>ab",
			function()
				local locs = require("haunt.sidekick").get_locations({ current_buffer = true })
				if locs and #locs > 0 then
					require("sidekick.cli").send({ msg = locs })
				else
					vim.notify("haunt.nvim: No bookmarks found in current buffer to send to Sidekick", vim.log.levels.WARN)
				end
			end,
			desc = "Sidekick: Send Buffer Haunt Bookmarks",
		},
		{
			"<leader>aB",
			function()
				local locs = require("haunt.sidekick").get_locations()
				if locs and #locs > 0 then
					require("sidekick.cli").send({ msg = locs })
				else
					vim.notify("haunt.nvim: No bookmarks found to send to Sidekick", vim.log.levels.WARN)
				end
			end,
			desc = "Sidekick: Send All Haunt Bookmarks",
		},
		{
			"<A-;>",
			function()
				require("sidekick").nes_jump_or_apply()
			end,
			desc = "Goto/Apply Next Edit Suggestion",
		},
	},
	opts = {
		cli = {
			win = {
				-- disable default `<c-p>` terminal-mode prompt keymap;
				-- `<leader>aP` already opens the prompt picker
				keys = { prompt = false },
				split = {
					width = 80,
				},
				float = {
					width = 0.75,
					height = 0.85,
				},
			},
			prompts = {
				haunt_all = function()
					return require("haunt.sidekick").get_locations()
				end,
				haunt_buffer = function()
					return require("haunt.sidekick").get_locations({ current_buffer = true })
				end,
			},
			tools = {
				antigravity = {
					cmd = { "agy" },
					is_proc = "\\<agy\\>",
					continue = { "--continue" },
				},
				opencode2 = {
					cmd = { "opencode2" },
					is_proc = "\\<opencode2\\>",
					continue = { "--continue" },
				},
			},
		},
	},
}
