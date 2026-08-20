local function update_bookmark_note(item, new_note)
	local haunt_store = require("haunt.store")
	local haunt_display = require("haunt.display")
	local bookmarks = haunt_store.get_all_raw()

	local target_bm = nil
	for _, bm in ipairs(bookmarks) do
		if (item.id and bm.id == item.id) or (bm.file == item.file and bm.line == item.pos[1]) then
			target_bm = bm
			break
		end
	end

	if not target_bm then
		return false
	end

	local bufnr = vim.fn.bufnr(target_bm.file)
	if bufnr == -1 or not vim.api.nvim_buf_is_loaded(bufnr) then
		bufnr = vim.fn.bufadd(target_bm.file)
		vim.fn.bufload(bufnr)
	end

	if target_bm.annotation_extmark_id and bufnr ~= -1 and vim.api.nvim_buf_is_valid(bufnr) then
		haunt_display.hide_annotation(bufnr, target_bm.annotation_extmark_id)
	end

	target_bm.note = (new_note and new_note ~= "") and new_note or nil
	if target_bm.note and bufnr ~= -1 and vim.api.nvim_buf_is_valid(bufnr) then
		target_bm.annotation_extmark_id = haunt_display.show_annotation(bufnr, target_bm.line, target_bm.note)
	else
		target_bm.annotation_extmark_id = nil
	end

	haunt_store.save()
	return true
end

local function open_haunt_picker(filter_current_buf)
	local haunt_api = require("haunt.api")
	local bookmarks = haunt_api.get_bookmarks()
	local current_file = vim.api.nvim_buf_get_name(0)

	if #bookmarks == 0 then
		vim.notify("haunt.nvim: No bookmarks found", vim.log.levels.INFO)
		return
	end

	local items = {}
	for i, bm in ipairs(bookmarks) do
		local path = bm.file or bm.filepath
		if not filter_current_buf or path == current_file then
			local relpath = vim.fn.fnamemodify(path, ":.")
			local filename = vim.fn.fnamemodify(path, ":t")
			local text = relpath .. ":" .. bm.line
			if bm.note and bm.note ~= "" then
				text = text .. " " .. bm.note
			end

			table.insert(items, {
				idx = i,
				score = i,
				id = bm.id,
				file = path,
				relpath = relpath,
				filename = filename,
				pos = { bm.line, 0 },
				line = bm.line,
				note = bm.note,
				text = text,
			})
		end
	end

	if filter_current_buf and #items == 0 then
		vim.notify("haunt.nvim: No bookmarks in current buffer", vim.log.levels.INFO)
		return
	end

	Snacks.picker({
		title = filter_current_buf and "Hauntings (Buffer)" or "Hauntings",
		items = items,
		format = function(item, _)
			local result = {}
			local dir = vim.fn.fnamemodify(item.relpath, ":h")
			dir = (dir == "." or dir == "") and "" or (dir .. "/")

			result[#result + 1] = { item.filename, "SnacksPickerFile" }
			if dir ~= "" then
				result[#result + 1] = { " " .. dir, "SnacksPickerDir" }
			end
			result[#result + 1] = { ":", "SnacksPickerIcon" }
			result[#result + 1] = { tostring(item.pos[1]), "SnacksPickerMatch" }

			if item.note and item.note ~= "" then
				result[#result + 1] = { " " .. item.note, "SnacksPickerComment" }
			end

			return result
		end,
		confirm = function(picker, item)
			if not item then
				return
			end
			picker:close()
			local bufnr = vim.fn.bufnr(item.file)
			if bufnr == -1 then
				vim.cmd("edit " .. vim.fn.fnameescape(item.file))
			else
				vim.cmd("buffer " .. bufnr)
			end
			vim.api.nvim_win_set_cursor(0, { item.line, 0 })
			vim.cmd("normal! zz")
		end,
		actions = {
			delete_bookmark = function(picker, item)
				item = item or picker:current()
				if item and item.id then
					haunt_api.delete_by_id(item.id)
					picker:close()
					vim.schedule(function()
						open_haunt_picker(filter_current_buf)
					end)
				end
			end,
			edit_annotation = function(picker, item)
				item = item or picker:current()
				if not item then
					return
				end
				picker:close()
				vim.schedule(function()
					vim.ui.input({
						prompt = "Edit Annotation: ",
						default = item.note or "",
					}, function(input)
						if input ~= nil then
							update_bookmark_note(item, input)
						end
						open_haunt_picker(filter_current_buf)
					end)
				end)
			end,
		},
		win = {
			input = {
				keys = {
					["<c-e>"] = { "edit_annotation", desc = "Edit annotation", mode = { "n", "i" } },
					["<c-d>"] = { "delete_bookmark", desc = "Delete bookmark", mode = { "n", "i" } },
					["e"] = { "edit_annotation", desc = "Edit annotation", mode = { "n" } },
					["d"] = { "delete_bookmark", desc = "Delete bookmark", mode = { "n" } },
				},
			},
			list = {
				keys = {
					["<c-e>"] = { "edit_annotation", desc = "Edit annotation", mode = { "n", "i" } },
					["<c-d>"] = { "delete_bookmark", desc = "Delete bookmark", mode = { "n", "i" } },
					["e"] = { "edit_annotation", desc = "Edit annotation", mode = { "n" } },
					["d"] = { "delete_bookmark", desc = "Delete bookmark", mode = { "n" } },
				},
			},
		},
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
				open_haunt_picker(false)
			end,
			desc = "Haunt: List bookmarks (all)",
		},
		{
			"<leader>Bb",
			function()
				open_haunt_picker(true)
			end,
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
