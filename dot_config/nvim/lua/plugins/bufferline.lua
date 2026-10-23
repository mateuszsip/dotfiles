return {
  "akinsho/bufferline.nvim",
  opts = {
    options = {
      separator_style = { "", "" },
      indicator = { style = "none" },
      name_formatter = function(buf)
        return " " .. buf.name
      end,
      custom_filter = function(buf, _)
        local buf_name = vim.api.nvim_buf_get_name(buf)
        if vim.fn.isdirectory(buf_name) == 1 then
          return false
        end
        return true
      end,
    },
    -- Bufferline shades each state from Normal's background, and that makes
    -- the tabline depend on autocmd order: plugin/after/transparency.lua
    -- clears Normal's background at startup, so bufferline derives "NONE" and
    -- nvim paints those cells with TabLineFill's grey (grey patches behind the
    -- indicator cell, the devicons, the diagnostics count/name of a buffer
    -- with warnings); on a :colorscheme reload its handler runs while Normal
    -- still has a bg, so it derives its own shades (#eae7dc for visible) that
    -- no longer match the bar. opts.highlights accepts a function, which
    -- bufferline calls with its derived table from its own setup and
    -- ColorScheme handler, so every state background can simply be forced
    -- from the state suffix -- synchronously, no autocmd and no deferred
    -- repaint.
    --
    -- The bar is the editor background (paper #fffcf0) so the tabline melts
    -- into the buffer; only inactive tabs keep a grey chip. Visible/selected
    -- tabs are paper too, told apart by bold.
    highlights = function(defaults)
      local paper, chip = "#fffcf0", "#e0ddd3"

      local hl = {}
      for name, spec in pairs(defaults.highlights) do
        -- state groups carry their state in the suffix
        spec.bg = (name:match("_visible$") or name:match("_selected$")) and paper or chip
        hl[name] = spec
      end

      return vim.tbl_deep_extend("force", hl, {
        fill = { fg = "#b7b5ac", bg = paper },
        background = { fg = "#b7b5ac", bg = chip },
        buffer = { fg = "#b7b5ac", bg = chip },
        buffer_visible = { fg = "#b7b5ac", bg = paper },
        buffer_selected = { fg = "#100f0f", bg = paper, bold = true },
        close_button = { fg = "#b7b5ac", bg = chip },
        close_button_visible = { fg = "#b7b5ac", bg = paper },
        close_button_selected = { fg = "#100f0f", bg = paper },
        modified = { fg = "#24837b", bg = chip },
        modified_visible = { fg = "#24837b", bg = paper },
        modified_selected = { fg = "#24837b", bg = paper },
      })
    end,
  },
}
