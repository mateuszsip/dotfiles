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
  },
}
