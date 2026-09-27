local M = {}

-- matches both JetBrains spec naming styles: `### NAME` and `# @name NAME`
local function match_request_name(line)
  return line:match("^###%s*(.+)$") or line:match("^#%s*@name%s+(.+)$")
end

local function pick_requests(title, results)
  if #results == 0 then
    vim.notify("rest: no named requests found. Use: ### MY_NAME or # @name MY_NAME", vim.log.levels.WARN)
    return
  end

  local function jump(r)
    if vim.api.nvim_buf_get_name(0) ~= r.file then
      vim.cmd("edit " .. vim.fn.fnameescape(r.file))
    end
    vim.api.nvim_win_set_cursor(0, { r.lnum, 0 })
    vim.cmd("normal! zz")
  end

  local items = vim.tbl_map(function(r)
    return { text = r.display, file = r.file, lnum = r.lnum }
  end, results)
  require("snacks.picker")({
    title = title,
    items = items,
    format = function(item, _picker)
      return { { item.text, "SnacksPickerLabel" } }
    end,
    confirm = function(ctx, item)
      ctx:close()
      jump({ file = item.file, lnum = item.lnum })
    end,
  })
end

function M.search_requests_in_file()
  local results = {}
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for lnum, line in ipairs(lines) do
    local name = match_request_name(line)
    if name then
      name = name:gsub("%s+$", "")
      table.insert(results, {
        file = vim.api.nvim_buf_get_name(0),
        lnum = lnum,
        display = name,
      })
    end
  end

  pick_requests("HTTP Requests", results)
end

function M.search_requests_in_dir(dir)
  dir = dir or vim.fn.getcwd()

  local files = {}
  vim.list_extend(files, vim.fn.glob(dir .. "/**/*.http", false, true))
  vim.list_extend(files, vim.fn.glob(dir .. "/**/*.rest", false, true))

  if #files == 0 then
    vim.notify("rest: no .http/.rest files found in " .. dir, vim.log.levels.WARN)
    return
  end

  local results = {}
  for _, filepath in ipairs(files) do
    local ok, lines = pcall(vim.fn.readfile, filepath)
    if ok then
      for lnum, line in ipairs(lines) do
        local name = match_request_name(line)
        if name then
          name = name:gsub("%s+$", "")
          local rel = vim.fn.fnamemodify(filepath, ":~:.")
          table.insert(results, {
            file = filepath,
            lnum = lnum,
            display = rel .. "  " .. name,
          })
        end
      end
    end
  end

  pick_requests("HTTP Requests", results)
end

return M
