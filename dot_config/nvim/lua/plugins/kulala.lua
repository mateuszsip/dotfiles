return {
  "mistweaverco/kulala.nvim",
  keys = {
    -- in-file search (not in LazyVim's util.rest extra)
    {
      "<leader>Rf",
      function() require("kulala").search() end,
      desc = "Find request in file",
      ft = { "http", "rest" },
    },
    -- directory-wide search
    {
      "<leader>RF",
      function() require("utils.kulala").search_requests_in_dir(vim.fn.getcwd()) end,
      desc = "Find HTTP requests in CWD",
    },
  },
}
