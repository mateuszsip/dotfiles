-- Panel list navigation on the shifted jkl; layout (see config/keymaps.lua):
-- k = Down = next entry, l = Up = previous entry. Closures defer the require
-- so lazy.nvim does not load diffview while parsing specs.
local function next_entry()
  require("diffview.actions").next_entry()
end

local function prev_entry()
  require("diffview.actions").prev_entry()
end

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
      -- j/; (Left/Right) stay unbound: they fall through to the global
      -- origami fold maps. The defaults hijack j = next entry, k = prev
      -- entry, l = open the selected entry — all three fight the layout.
      -- List form (not ["k"] = fn) so the entries carry a desc for which-key.
      file_panel = {
        ["q"] = "<cmd>DiffviewClose<cr>",
        ["<esc>"] = "<cmd>DiffviewClose<cr>",
        { "n", "k", next_entry, { desc = "Bring the cursor to the next file entry" } },
        { "n", "l", prev_entry, { desc = "Bring the cursor to the previous file entry" } },
        ["j"] = false,
      },
      file_history_panel = {
        ["q"] = "<cmd>DiffviewClose<cr>",
        ["<esc>"] = "<cmd>DiffviewClose<cr>",
        { "n", "k", next_entry, { desc = "Bring the cursor to the next file entry" } },
        { "n", "l", prev_entry, { desc = "Bring the cursor to the previous file entry" } },
        ["j"] = false,
      },
    },
  },
}
