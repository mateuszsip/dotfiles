return {
  "Myzel394/easytables.nvim",
  ft = "markdown",
  keys = {
    {
      "<leader>mn",
      function()
        vim.ui.input({ prompt = "Table dimensions (e.g. 3x3): " }, function(input)
          if input and input ~= "" then
            vim.cmd("EasyTablesCreateNew " .. input)
          end
        end)
      end,
      desc = "Markdown: New table",
      ft = "markdown",
    },
    { "<leader>me", "<cmd>EasyTablesImportThisTable<cr>", desc = "Markdown: Edit table", ft = "markdown" },
  },
  config = function()
    require("easytables").setup()
  end,
}
