return {
  "cbochs/grapple.nvim",
  dependencies = {
    { "nvim-tree/nvim-web-devicons", lazy = true },
  },
  opts = {
    scope = "cwd",
    icons = true,
    status = true,
  },
  keys = {
    { "<leader>h", "<cmd>Grapple toggle_tags<cr>", desc = "Grapple toggle tags menu" },
    { "<leader>H", "<cmd>Grapple toggle<cr>", desc = "Grapple tag current file" },
  },
}
