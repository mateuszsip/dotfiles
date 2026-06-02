return {
  "necrom4/convy.nvim",
  cmd = { "Convy", "ConvySeparator" },
  opts = {
    notifications = true,
    separator = " ",
    window = {
      position = "left",
      width = 36,
    },
  },
  keys = {
    { "<leader>uc", ":Convy<CR>", desc = "Convy: interactive converter", mode = { "n", "v" }, silent = true },
    { "<leader>us", ":ConvySeparator<CR>", desc = "Convy: set separator", mode = { "v" }, silent = true },
  },
}
