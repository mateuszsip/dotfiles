local function make_open_fn(direction)
  return function()
    local bufnr = vim.api.nvim_get_current_buf()
    local row = vim.api.nvim_win_get_cursor(0)[1] - 1
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    local in_block, start_row, source_lines = false, nil, {}
    local found = {}
    for i, line in ipairs(lines) do
      local lnum = i - 1
      if not in_block and line:match("^%s*```mermaid") then
        in_block, start_row, source_lines = true, lnum, {}
      elseif in_block and line:match("^%s*```%s*$") then
        in_block = false
        if row >= start_row and row <= lnum then
          found = source_lines
          break
        end
        source_lines = {}
      elseif in_block then
        table.insert(source_lines, line)
      end
    end

    if #found == 0 then
      vim.notify("No mermaid diagram at cursor", vim.log.levels.INFO)
      return
    end

    local source = table.concat(found, "\n")
    local path = vim.fn.resolve(
      vim.fn.stdpath("cache") .. "/diagram-cache/mermaid/" .. vim.fn.sha256("mermaid:" .. source) .. ".png"
    )

    local function open_split()
      vim.cmd(direction == "h" and "split" or "vsplit")
      local win = vim.api.nvim_get_current_win()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_win_set_buf(win, buf)
      vim.bo[buf].buftype = "nofile"
      vim.bo[buf].bufhidden = "wipe"
      vim.wo[win].number = false
      vim.wo[win].relativenumber = false
      vim.wo[win].signcolumn = "no"
      vim.wo[win].statuscolumn = ""
      vim.wo[win].foldcolumn = "0"

      local unique_path = vim.fn.tempname() .. ".png"
      local convert = vim.fn.executable("magick") == 1 and "magick" or "convert"
      vim.fn.system(string.format("%s '%s' -trim +repage '%s'", convert, path, unique_path))

      -- Fill buffer with blank lines so <C-d>/<C-u> scrolling works.
      -- Vertical: image fills split width, may be tall → compute scaled rows.
      -- Horizontal: image is constrained to split height → no extra lines needed.
      local term_size = require("image.utils.term").get_size()
      if term_size and direction == "v" then
        local dims = vim.fn.system(string.format(
          "%s identify -format '%%wx%%h' '%s' 2>/dev/null",
          vim.fn.executable("magick") == 1 and "magick" or "identify",
          unique_path
        ))
        local iw, ih = dims:match("(%d+)x(%d+)")
        iw, ih = tonumber(iw), tonumber(ih)
        if iw and ih then
          local win_cols = vim.api.nvim_win_get_width(win)
          local num_lines = math.ceil(ih * win_cols * term_size.cell_width / iw / term_size.cell_height)
          if num_lines > 1 then
            local blank = {}
            for i = 1, num_lines do blank[i] = "" end
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, blank)
          end
        end
      end

      -- Vertical: fill split width, allow tall images (scroll to see rest).
      -- Horizontal: constrain to split height, width adjusts by aspect ratio.
      local max_height_pct = direction == "v" and 9999 or 100

      local current_image = nil
      local function render_image()
        if current_image then current_image:clear() end
        current_image = require("image").from_file(unique_path, {
          buffer = buf,
          window = win,
          inline = true,
          x = 0,
          y = 0,
          width = 9999,
          max_height_window_percentage = max_height_pct,
        })
        if current_image then current_image:render() end
      end

      render_image()

      vim.api.nvim_create_autocmd({ "WinResized", "VimResized" }, {
        buffer = buf,
        callback = function()
          if vim.api.nvim_win_is_valid(win) then render_image() end
        end,
      })

      vim.keymap.set("n", "q", function()
        if current_image then current_image:clear() end
        vim.cmd("close")
      end, { buffer = buf, desc = "Close diagram" })
    end

    if vim.fn.filereadable(path) == 1 then
      open_split()
      return
    end

    local renderer = require("diagram.renderers.mermaid")
    local result = renderer.render(table.concat(found, "\n"), { background = "transparent", scale = 3 })
    if not result then return end

    local timer = vim.loop.new_timer()
    timer:start(0, 100, vim.schedule_wrap(function()
      if vim.fn.jobwait({ result.job_id }, 0)[1] ~= -1 then
        timer:stop()
        timer:close()
        open_split()
      end
    end))
  end
end

return {
  "3rd/diagram.nvim",
  dependencies = {
    { "3rd/image.nvim", opts = {} },
  },
  ft = { "markdown" },
  keys = {
    { "<leader>md", make_open_fn("v"), desc = "Open diagram (vertical split)" },
    { "<leader>mD", make_open_fn("h"), desc = "Open diagram (horizontal split)" },
  },
  opts = {
    renderer_options = {
      mermaid = {
        background = "transparent",
        scale = 3,
      },
      plantuml = { charset = "utf-8" },
    },
  },
}
