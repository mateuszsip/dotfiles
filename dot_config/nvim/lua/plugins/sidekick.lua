return {
  "folke/sidekick.nvim",
  keys = {
    { "<leader>ac", function() require("sidekick.cli").toggle({ name = "claude", focus = true }) end, desc = "Sidekick Toggle Claude" },
    { "<leader>ao", function() require("sidekick.cli").toggle({ name = "opencode", focus = true }) end, desc = "Sidekick Toggle Opencode" },
  },
  opts = {
    cli = {
      win = {
        split = {
          width = 30,
        },
        float = {
          width = 0.6,
          height = 0.7,
        },
      },
    },
  },
}
