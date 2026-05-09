local M = {}

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

  local items = vim.tbl_map(function(r)
    return { text = r.display, file = r.file, lnum = r.lnum }
  end, results)
  require("snacks.picker")({
    title = "HTTP Requests",
    items = items,
    confirm = function(ctx, item)
      ctx:close()
      jump({ file = item.file, lnum = item.lnum })
    end,
  })
end

return M
