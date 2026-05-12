return {
  "akinsho/bufferline.nvim",
  opts = {
    options = {
      separator_style = "thin",
      indicator = { style = "underline" },
      name_formatter = function(buf)
        return " " .. buf.name .. " "
      end,
    },
  },
}
