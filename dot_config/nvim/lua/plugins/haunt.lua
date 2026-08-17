local function buffer_bookmarks_picker()
	local haunt_api = require("haunt.api")
	local bookmarks = haunt_api.get_bookmarks()
	local current_file = vim.api.nvim_buf_get_name(0)
	local items = {}

	for _, bm in ipairs(bookmarks) do
		local path = bm.file or bm.filepath
		if path == current_file then
			table.insert(items, {
				id = bm.id,
				file = path,
				pos = { bm.line, 0 },
				text = string.format("%d: %s", bm.line, bm.note or "(bookmark)"),
			})
		end
	end

	if #items == 0 then
		vim.notify("haunt.nvim: No bookmarks in current buffer", vim.log.levels.INFO)
		return
	end

	Snacks.picker({
		title = "Haunt Bookmarks (Buffer)",
		items = items,
		format = "file",
		confirm = function(picker, item)
			picker:close()
			if item then
				vim.api.nvim_win_set_cursor(0, item.pos)
			end
		end,
	})
end

return {
	"TheNoeTrevino/haunt.nvim",
	event = "VeryLazy",
	dependencies = {
		"folke/snacks.nvim",
	},
	opts = {
		sign = "󱙝",
		sign_hl = "DiagnosticInfo",
		virt_text_hl = "HauntAnnotation",
		annotation_prefix = " 󰆉 ",
		annotation_suffix = "",
		per_branch_bookmarks = true,
		picker = "snacks",
		picker_keys = {
			delete = { key = "d", mode = { "n" } },
			edit_annotation = { key = "a", mode = { "n" } },
		},
	},
	keys = {
		{
			"<leader>Ba",
			function()
				require("haunt.api").annotate()
			end,
			desc = "Haunt: Annotate",
		},
		{
			"<leader>Bt",
			function()
				require("haunt.api").toggle_annotation()
			end,
			desc = "Haunt: Toggle annotation",
		},
		{
			"<leader>BT",
			function()
				require("haunt.api").toggle_all_lines()
			end,
			desc = "Haunt: Toggle all annotations",
		},
		{
			"<leader>BB",
			function()
				require("haunt.picker").show()
			end,
			desc = "Haunt: List bookmarks (all)",
		},
		{
			"<leader>Bb",
			buffer_bookmarks_picker,
			desc = "Haunt: List bookmarks (buffer)",
		},
		{
			"<leader>Bd",
			function()
				require("haunt.api").delete()
			end,
			desc = "Haunt: Delete bookmark",
		},
		{
			"<leader>BC",
			function()
				require("haunt.api").clear_all()
			end,
			desc = "Haunt: Clear all bookmarks",
		},
		{
			"<leader>Bq",
			function()
				require("haunt.api").to_quickfix()
			end,
			desc = "Haunt: Send to quickfix",
		},
		{
			"<leader>By",
			function()
				require("haunt.api").yank_locations({ current_buffer = true })
			end,
			desc = "Haunt: Yank locations (buffer)",
		},
		{
			"<leader>BY",
			function()
				require("haunt.api").yank_locations()
			end,
			desc = "Haunt: Yank locations (all)",
		},
		{
			"<leader>Bs",
			function()
				local locs = require("haunt.sidekick").get_locations({ current_buffer = true })
				if locs and #locs > 0 then
					require("sidekick.cli").send({ msg = locs })
				else
					vim.notify("haunt.nvim: No bookmarks found in current buffer to send to Sidekick", vim.log.levels.WARN)
				end
			end,
			desc = "Haunt: Send buffer bookmarks to Sidekick CLI",
		},
		{
			"<leader>BS",
			function()
				local locs = require("haunt.sidekick").get_locations()
				if locs and #locs > 0 then
					require("sidekick.cli").send({ msg = locs })
				else
					vim.notify("haunt.nvim: No bookmarks found to send to Sidekick", vim.log.levels.WARN)
				end
			end,
			desc = "Haunt: Send all bookmarks to Sidekick CLI",
		},
	},
}
