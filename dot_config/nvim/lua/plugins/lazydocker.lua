return {
  "folke/snacks.nvim",
  keys = {
    {
      "<leader>ld",
      function()
        Snacks.terminal("lazydocker", { cwd = vim.fn.getcwd() })
      end,
      desc = "LazyDocker",
    },
  },
}
