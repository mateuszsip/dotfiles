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
				require("sidekick.cli").toggle({ name = "opencode", focus = true })
			end,
			desc = "Sidekick Toggle Opencode",
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
				split = {
					width = 80,
				},
				float = {
					width = 0.75,
					height = 0.85,
				},
			},
		},
	},
}
