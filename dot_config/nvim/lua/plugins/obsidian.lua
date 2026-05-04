return {
  "obsidian-nvim/obsidian.nvim",
  version = "*", -- recommended, use latest release instead of latest commit
  keys = {
    -- Daily notes (global, work from any buffer)
    { "<leader>ot", "<cmd>Obsidian today<CR>", desc = "Obsidian: Today's note" },
    { "<leader>or", "<cmd>Obsidian yesterday<CR>", desc = "Obsidian: Yesterday's note" },
    { "<leader>oy", "<cmd>Obsidian tomorrow<CR>", desc = "Obsidian: Tomorrow's note" },
    { "<leader>od", "<cmd>Obsidian dailies<CR>", desc = "Obsidian: Browse daily notes" },
    -- Quick access
    { "<leader>os", "<cmd>Obsidian search<CR>", desc = "Obsidian: Search" },
    { "<leader>oq", "<cmd>Obsidian quick_switch<CR>", desc = "Obsidian: Quick switch" },
  },
  opts = {
    legacy_commands = false,
    workspaces = {
      {
        name = "personal",
        path = "~/.notes/personal",
      },
      {
        name = "work",
        path = "~/.notes/work",
      },
    },

    daily_notes = {
      folder = ".notes/daily",
    },

    -- Disable footer to prevent rg running outside workspace on BufEnter
    footer = { enabled = false },
    -- Or if you want footer but not the full UI rendering:
    -- ui = { enable = false },

    callbacks = {
      -- Buffer-local mappings, only active inside Obsidian notes
      enter_note = function()
        local actions = require("obsidian.actions")

        -- Toggle checkbox (cycles through states: [ ] -> [x] -> etc.)
        -- Note: <CR> (smart_action) already toggles when cursor is ON a checkbox.
        -- This mapping works from anywhere on the line.
        vim.keymap.set("n", "<leader>oc", "<cmd>Obsidian toggle_checkbox<CR>", {
          buffer = true,
          desc = "Obsidian: Toggle checkbox",
        })

        -- Link navigation (replaces default ]o / [o)
        vim.keymap.set("n", "<Tab>", function()
          actions.nav_link("next")
        end, { buffer = true, desc = "Obsidian: Next link" })
        vim.keymap.set("n", "<S-Tab>", function()
          actions.nav_link("prev")
        end, { buffer = true, desc = "Obsidian: Prev link" })
      end,
    },
  },
}
