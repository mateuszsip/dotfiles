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
    -- Bufferline shades every state from Normal's background, but
    -- plugin/after/transparency.lua clears that background, so the whole bar
    -- collapses into one transparent tone and only bold marks the current
    -- buffer. These are the values bufferline derives for flexoki-light with
    -- a paper Normal bg: darkest bar, shaded inactive tabs, paper-white
    -- active tab. Set through opts (not an autocmd) so bufferline re-applies
    -- them itself on every ColorScheme.
    highlights = {
      fill = { fg = "#b7b5ac", bg = "#ccc9c0" },
      background = { fg = "#b7b5ac", bg = "#e0ddd3" },
      buffer = { fg = "#b7b5ac", bg = "#e0ddd3" },
      buffer_visible = { fg = "#b7b5ac", bg = "#eae7dc" },
      buffer_selected = { fg = "#100f0f", bg = "#fffcf0", bold = true },
      close_button = { fg = "#b7b5ac", bg = "#e0ddd3" },
      close_button_visible = { fg = "#b7b5ac", bg = "#eae7dc" },
      close_button_selected = { fg = "#100f0f", bg = "#fffcf0" },
      modified = { fg = "#24837b", bg = "#e0ddd3" },
      modified_visible = { fg = "#24837b", bg = "#eae7dc" },
      modified_selected = { fg = "#24837b", bg = "#fffcf0" },
    },
  },
}
