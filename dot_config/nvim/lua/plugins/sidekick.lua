return {
  "folke/sidekick.nvim",
  keys = {
    {
      "<leader>ac",
      function()
        require("sidekick.cli").toggle({ name = "claude", focus = true })
      end,
      desc = "Sidekick Toggle Claude",
    },
    {
      "<leader>ao",
      function()
        require("sidekick.cli").toggle({ name = "opencode", focus = true })
      end,
      desc = "Sidekick Toggle Opencode",
    },
    {
      "<A-;>",
      function()
        require("sidekick").nes_jump_or_apply()
      end,
      desc = "Goto/Apply Next Edit Suggestion",
    },
  },
  opts = {
    cli = {
      win = {
        split = {
          width = 60,
        },
        float = {
          width = 0.75,
          height = 0.85,
        },
      },
    },
  },
}
