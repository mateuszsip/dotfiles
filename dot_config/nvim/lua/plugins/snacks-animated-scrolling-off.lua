return {
	"folke/snacks.nvim",
	opts = {
		scroll = {
			enabled = false, -- Disable scrolling animations
		},
		picker = {
			win = {
				input = {
					keys = {
						["<PageDown>"] = { "list_scroll_down", mode = { "i", "n" } },
						["<PageUp>"] = { "list_scroll_up", mode = { "i", "n" } },
						["<A-;>"] = { "cycle_win", mode = { "i", "n" } },
						["<A-j>"] = { "cycle_win", mode = { "i", "n" } },
						["<A-w>"] = "none",
					},
				},
				list = {
					keys = {
						["<A-;>"] = "cycle_win",
						["<A-j>"] = "cycle_win",
						["<A-w>"] = "none",
					},
				},
				preview = {
					keys = {
						["<A-;>"] = "cycle_win",
						["<A-j>"] = "cycle_win",
						["<A-w>"] = "none",
					},
				},
			},
		},
	},
}
