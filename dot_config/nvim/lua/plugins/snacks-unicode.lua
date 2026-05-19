return {
  {
    "ecruzolivera/snacks-unicode",
    dependencies = { "folke/snacks.nvim" },
    event = "VeryLazy",
    config = function(_, opts)
      require("snacks-unicode").setup(opts)
    end,
    keys = {
      {
        "<leader>su",
        function()
          Snacks.picker.pick("unicode")
        end,
        desc = "Unicode Symbols",
      },
      {
        "<leader>se",
        function()
          Snacks.picker.pick("unicode", { categories = { "emoji" } })
        end,
        desc = "Emoji",
      },
    },
  },
}
