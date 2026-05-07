local M = {}

-- Scan dir recursively for named requests (### NAME) across all .http/.rest files
-- and open a picker to jump to them.
function M.search_requests_in_dir(dir)
  dir = dir or vim.fn.getcwd()

  local files = {}
  vim.list_extend(files, vim.fn.glob(dir .. "/**/*.http", false, true))
  vim.list_extend(files, vim.fn.glob(dir .. "/**/*.rest", false, true))

  if #files == 0 then
    vim.notify("kulala: no .http/.rest files found in " .. dir, vim.log.levels.WARN)
    return
  end

  local results = {}
  for _, filepath in ipairs(files) do
    local ok, lines = pcall(vim.fn.readfile, filepath)
    if ok then
      for lnum, line in ipairs(lines) do
        local name = line:match("^###%s*(.+)$")
        if name then
          name = name:gsub("%s+$", "")
          local rel = vim.fn.fnamemodify(filepath, ":~:.")
          table.insert(results, {
            file = filepath,
            lnum = lnum,
            name = name,
            display = rel .. "  " .. name,
          })
        end
      end
    end
  end

  if #results == 0 then
    vim.notify("kulala: no named requests found. Use: ### MY_NAME", vim.log.levels.WARN)
    return
  end

  local function jump(r)
    vim.cmd("edit " .. vim.fn.fnameescape(r.file))
    vim.api.nvim_win_set_cursor(0, { r.lnum, 0 })
    vim.cmd("normal! zz")
  end

  -- snacks.picker
  local has_snacks, snacks_picker = pcall(require, "snacks.picker")
  if has_snacks then
    local items = vim.tbl_map(function(r)
      return { text = r.display, file = r.file, lnum = r.lnum }
    end, results)
    snacks_picker({
      title = "HTTP Requests",
      items = items,
      confirm = function(ctx, item)
        ctx:close()
        jump({ file = item.file, lnum = item.lnum })
      end,
    })
    return
  end

  -- telescope fallback
  local has_telescope = pcall(require, "telescope")
  if has_telescope then
    local action_state = require("telescope.actions.state")
    local actions = require("telescope.actions")
    local finders = require("telescope.finders")
    local pickers = require("telescope.pickers")
    local conf = require("telescope.config").values

    pickers
      .new({}, {
        prompt_title = "HTTP Requests",
        finder = finders.new_table({
          results = results,
          entry_maker = function(r)
            return { value = r, display = r.display, ordinal = r.display }
          end,
        }),
        attach_mappings = function(prompt_bufnr)
          actions.select_default:replace(function()
            local sel = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            jump(sel.value)
          end)
          return true
        end,
        sorter = conf.generic_sorter({}),
      })
      :find()
    return
  end

  -- vim.ui.select fallback
  local labels = vim.tbl_map(function(r) return r.display end, results)
  local by_label = {}
  for _, r in ipairs(results) do
    by_label[r.display] = r
  end
  vim.ui.select(labels, { prompt = "HTTP Requests" }, function(choice)
    if choice then jump(by_label[choice]) end
  end)
end

return M
