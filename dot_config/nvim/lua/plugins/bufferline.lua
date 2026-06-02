return {
  "akinsho/bufferline.nvim",
  opts = {
    options = {
      separator_style = { "", "" },
      indicator = { style = "none" },
      name_formatter = function(buf)
        return " " .. buf.name
      end,
    },
  },
}
