return {
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup()
    end,
  },
  {
    "gregorias/nvim-surround-wk",
    dependencies = { "kylechui/nvim-surround", "folke/which-key.nvim" },
    event = "VeryLazy",
    config = function()
      require("nvim-surround-wk").setup()
    end,
  },
}
