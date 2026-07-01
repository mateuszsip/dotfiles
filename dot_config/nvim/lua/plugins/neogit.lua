return {
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
    },
    cmd = "Neogit",
    opts = {
      kind = "floating",
      graph_style = "unicode",
      commit_order = "topo",
      sort_branches = "-refname",
      disable_insert_on_commit = "auto",
      auto_show_console = true,
      auto_close_console = true,
      integrations = { snacks = true, diffview = false, telescope = false },
      sections = {
        untracked = { folded = false },
        unstaged = { folded = false },
        staged = { folded = false },
        stashes = { folded = true },
        unpulled_upstream = { folded = true },
        unmerged_upstream = { folded = true },
        unpulled_pushRemote = { folded = true },
        unmerged_pushRemote = { folded = true },
        recent = { folded = true },
        rebase = { folded = true },
        sequencer = { folded = true },
        bisect = { folded = true },
      },
      -- Override defaults so the physical jkl; layout stays consistent inside Neogit.
      -- Defaults (config.lua:696) bind `j`=MoveDown and `k`=MoveUp as buffer-local maps,
      -- which override this config's global jkl; remap, so pressing physical `k` (your
      -- "Down" key) would MoveUp with stock Neogit. Swap to match the physical layout.
      mappings = {
        -- Move LogPopup from `l` (default, config.lua:689) to `L` so the
        -- physical `l` key is free for MoveUp in the status buffer. This
        -- also drops the default `L`→MarginPopup binding (rarely used).
        popup = {
          ["l"] = false,
          ["L"] = "LogPopup",
        },
        status = {
          ["j"] = false,
          [";"] = false,
          ["k"] = "MoveDown",
          ["l"] = "MoveUp",
          ["<c-j>"] = false,
          ["<c-k>"] = "PeekDown",
          ["<c-l>"] = "PeekUp",
        },
        rebase_editor = {
          -- default `gj`=MoveDown, `gk`=MoveUp — wrong way for jkl;. Swap so
          -- `g`+`k` moves the commit down and `g`+`l` moves it up.
          ["gj"] = false,
          ["gk"] = "MoveDown",
          ["gl"] = "MoveUp",
        },
      },
    },
    keys = {
      { "<leader>gg", "<cmd>Neogit<cr>", desc = "Neogit (status)" },
      { "<leader>gG", "<cmd>Neogit cwd<cr>", desc = "Neogit (cwd)" },
      { "<leader>gc", "<cmd>Neogit commit<cr>", desc = "Neogit Commit" },
      { "<leader>gb", "<cmd>Neogit branch<cr>", desc = "Neogit Branch" },
      { "<leader>gl", "<cmd>Neogit log<cr>", desc = "Neogit Log" },
    },
  },
}
