return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
  keys = {
    { "<leader>gdm", function() require("utils.git").diffview_against(false) end, desc = "Diff vs main/master" },
    { "<leader>gdM", function() require("utils.git").diffview_against(true) end, desc = "Diff vs origin/main/master" },
    { "<leader>gdc", "<cmd>DiffviewClose<cr>", desc = "Close Diffview" },
    { "<leader>gdh", "<cmd>DiffviewFileHistory %<cr>", desc = "File History" },
    { "<leader>gdH", "<cmd>DiffviewFileHistory<cr>", desc = "Repo History" },
  },
  opts = {},
}
