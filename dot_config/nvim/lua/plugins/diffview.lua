return {
  -- "sindrets/diffview.nvim",
  "dlyongemallo/diffview-plus.nvim",
  cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
  keys = {
    {
      "<leader>gdm",
      function()
        require("utils.git").diffview_against(false)
      end,
      desc = "Diff vs main/master",
    },
    {
      "<leader>gdM",
      function()
        require("utils.git").diffview_against(true)
      end,
      desc = "Diff vs origin/main/master",
    },
    { "<leader>gdh", "<cmd>DiffviewFileHistory %<cr>", desc = "File History" },
    { "<leader>gdH", "<cmd>DiffviewFileHistory<cr>", desc = "Repo History" },
  },
  config = function(_, opts)
    require("diffview").setup(opts)
    local close = function()
      vim.cmd("DiffviewClose")
    end
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "DiffviewFiles", "DiffviewFileHistory" },
      callback = function(args)
        vim.keymap.set("n", "<esc>", close, { buffer = args.buf, silent = true, desc = "Close Diffview" })
        vim.keymap.set("n", "q", close, { buffer = args.buf, silent = true, desc = "Close Diffview" })
      end,
    })
  end,
  opts = {
    keymaps = {
      view = { ["q"] = "<cmd>DiffviewClose<cr>", ["<esc>"] = "<cmd>DiffviewClose<cr>" },
      file_panel = { ["q"] = "<cmd>DiffviewClose<cr>", ["<esc>"] = "<cmd>DiffviewClose<cr>" },
    },
  },
}
