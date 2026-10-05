-- LazyVim core trouble binds <leader>cs and <leader>cS; outline.lua's cs/cS
-- pair owns both prefixes per its documented intent, and the winner flips
-- per launch. Disable both here so outline owns them deterministically.
return {
  "folke/trouble.nvim",
  keys = {
    { "<leader>cs", false },
    { "<leader>cS", false },
  },
}

