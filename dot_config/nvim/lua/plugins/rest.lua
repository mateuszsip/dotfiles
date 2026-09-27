-- rest.nvim replaces mistweaverco/kulala.nvim (repo was deleted from GitHub).
-- Same JetBrains .http spec, so existing `### NAME` files keep working.
return {
  "rest-nvim/rest.nvim",
  init = function()
    -- rest.nvim's ftdetect only maps .http; keep .rest files working too
    vim.filetype.add({ extension = { rest = "http" } })
  end,
  ft = { "http", "rest" },
  keys = {
    { "<leader>R", "", desc = "+Rest" },
    -- same keys as the old LazyVim util.rest extra where rest.nvim has equivalents
    { "<leader>Rs", "<cmd>Rest run<cr>", desc = "Send the request", ft = { "http", "rest" } },
    { "<leader>Rr", "<cmd>Rest last<cr>", desc = "Replay the last request", ft = { "http", "rest" } },
    { "<leader>Rc", "<cmd>Rest curl yank<cr>", desc = "Copy as cURL", ft = { "http", "rest" } },
    { "<leader>Re", "<cmd>Rest env select<cr>", desc = "Select environment", ft = { "http", "rest" } },
    { "<leader>Ro", "<cmd>Rest open<cr>", desc = "Open result pane", ft = { "http", "rest" } },
    -- in-file search (rest.nvim has no built-in search)
    {
      "<leader>Rf",
      function()
        require("utils.rest").search_requests_in_file()
      end,
      desc = "Find request in file",
      ft = { "http", "rest" },
    },
    -- directory-wide search
    {
      "<leader>RF",
      function()
        require("utils.rest").search_requests_in_dir(vim.fn.getcwd())
      end,
      desc = "Find HTTP requests in CWD",
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "http", "graphql" } },
  },
}
