return {
  "akinsho/bufferline.nvim",
  opts = {
    options = {
      separator_style = "thin",
      indicator = { style = "none" },
      name_formatter = function(buf)
        return " " .. buf.name .. " "
      end,
    },
  },
}
