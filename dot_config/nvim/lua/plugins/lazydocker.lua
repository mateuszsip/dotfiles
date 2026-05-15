return {
  "folke/snacks.nvim",
  keys = {
    {
      "ll",
      function()
        Snacks.terminal("lazydocker", { cwd = vim.fn.getcwd() })
      end,
      desc = "LazyDocker",
    },
  },
}
