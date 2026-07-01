local function open_visits(cwd)
  local visits = require("mini.visits")
  local paths = visits.list_paths(cwd, { sort = visits.gen_sort.default({ recency_weight = 0.5 }) })
  if #paths == 0 then
    Snacks.notify.warn("No visits found" .. (cwd and " for " .. cwd or ""))
    return
  end
  local items = {}
  for _, path in ipairs(paths) do
    items[#items + 1] = {
      file = path,
      text = path,
      cwd = cwd and cwd ~= "" and cwd or nil,
    }
  end
  Snacks.picker.pick({
    source = "visits",
    items = items,
    title = "Visited files" .. (cwd and cwd ~= "" and (" — " .. cwd) or " — all"),
    format = function(item, _)
      local ret = {}
      local icon, icon_hl = Snacks.util.icon(item.file, "file")
      ret[#ret + 1] = { icon, icon_hl }
      ret[#ret + 1] = { vim.fn.fnamemodify(item.file, ":~:."), "SnacksPickerFile" }
      return ret
    end,
    confirm = function(picker, item)
      picker:close()
      vim.cmd("edit " .. vim.fn.fnameescape(item.file))
    end,
  })
end

return {
  "nvim-mini/mini.visits",
  lazy = true,
  keys = {
    {
      "<leader>fv",
      function()
        open_visits(nil)
      end,
      desc = "Visits (cwd)",
    },
    {
      "<leader>fa",
      function()
        open_visits("")
      end,
      desc = "Visits (all)",
    },
  },
  opts = {},
}

