return {
  {
    "tpope/vim-dadbod",
    dependencies = {
      "kristijanhusak/vim-dadbod-ui",
    },
    lazy = true,
    keys = {
      { "<leader>DD", desc = "Toggle DB UI" },
      { "<leader>Dr", desc = "Refresh DB credentials from Vault" },
    },
    config = function()
      local dbcreds = require("utils.dbcreds")

      vim.g.db_ui_table_helpers = {
        mysql = {
          Count = "SELECT count(*) FROM `{table}`",
        },
        postgresql = {
          Count = 'SELECT count(*) FROM "{schema}"."{table}"',
        },
      }

      vim.keymap.set("n", "<leader>DD", function()
        local is_open = vim.iter(vim.api.nvim_list_wins()):any(function(w)
          return vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "dbui"
        end)
        if not is_open then
          dbcreds.refresh()
        end
        vim.cmd("DBUIToggle")
      end, { desc = "Toggle DB UI" })

      vim.keymap.set("n", "<leader>Dr", function()
        dbcreds.refresh()
        vim.notify("DB credentials refreshed from Vault")
      end, { desc = "Refresh DB credentials from Vault" })
    end,
  },
  {
    "davesavic/dadbod-ui-yank",
    dependencies = { "kristijanhusak/vim-dadbod-ui" },
    keys = {
      { "<leader>Dyj", desc = "Yank row as JSON" },
      { "<leader>Dyc", desc = "Yank row as CSV" },
      { "<leader>Dyx", desc = "Yank row as XML" },
      { "<leader>DyJ", desc = "Yank all rows as JSON" },
      { "<leader>DyC", desc = "Yank all rows as CSV" },
      { "<leader>DyX", desc = "Yank all rows as XML" },
      { "<leader>Dyj", mode = "v", desc = "Yank selection as JSON" },
      { "<leader>Dyc", mode = "v", desc = "Yank selection as CSV" },
      { "<leader>Dyx", mode = "v", desc = "Yank selection as XML" },
    },
    config = function()
      require("dadbod-ui-yank").setup()

      vim.keymap.set("n", "<leader>Dyj", "<cmd>DBUIYankAsJSON<CR>", { desc = "Yank row as JSON" })
      vim.keymap.set("n", "<leader>Dyc", "<cmd>DBUIYankAsCSV<CR>", { desc = "Yank row as CSV" })
      vim.keymap.set("n", "<leader>Dyx", "<cmd>DBUIYankAsXML<CR>", { desc = "Yank row as XML" })
      vim.keymap.set("n", "<leader>DyJ", "<cmd>%DBUIYankAsJSON<CR>", { desc = "Yank all rows as JSON" })
      vim.keymap.set("n", "<leader>DyC", "<cmd>%DBUIYankAsCSV<CR>", { desc = "Yank all rows as CSV" })
      vim.keymap.set("n", "<leader>DyX", "<cmd>%DBUIYankAsXML<CR>", { desc = "Yank all rows as XML" })
      vim.keymap.set("v", "<leader>Dyj", ":'<,'>DBUIYankAsJSON<CR>", { desc = "Yank selection as JSON" })
      vim.keymap.set("v", "<leader>Dyc", ":'<,'>DBUIYankAsCSV<CR>", { desc = "Yank selection as CSV" })
      vim.keymap.set("v", "<leader>Dyx", ":'<,'>DBUIYankAsXML<CR>", { desc = "Yank selection as XML" })
    end,
  },
}
