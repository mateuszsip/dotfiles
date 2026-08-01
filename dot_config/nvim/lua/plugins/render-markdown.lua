return {
	"MeanderingProgrammer/render-markdown.nvim",
	opts = {
		file_types = { "markdown" },
		code = {
			width = "block",
			left_margin = 2,
			left_pad = 6,
			right_pad = 8,
			language_pad = 2,
			sign = false,
			border = "none",
			background_inset = 0,
			highlight_language = "RenderMarkdownCodeLang",
		},
		heading = {
			icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
		},
		pipe_table = {
			enabled = true,
			cell = "raw",
		},
		yaml = {
			enabled = false,
		},
		html = {
			enabled = true,
			tag = {
				h4 = { icon = "▸ " },
			},
		},
	},
	ft = { "markdown" },
	config = function(_, opts)
		require("render-markdown").setup(opts)
		local function fix_bullet_hl()
			local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
			vim.api.nvim_set_hl(0, "RenderMarkdownBullet", { fg = normal.fg, bg = "NONE" })
		end
		fix_bullet_hl()
		vim.api.nvim_create_autocmd("ColorScheme", { callback = fix_bullet_hl })
	end,
}
