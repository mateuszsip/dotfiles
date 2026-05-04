return {
  "obsidian-nvim/obsidian.nvim",
  version = "*", -- recommended, use latest release instead of latest commit
  ft = "markdown",
  keys = {
    -- Daily notes (global, work from any buffer)
    { "<leader>ot", "<cmd>Obsidian today<CR>", desc = "Obsidian: Today's note" },
    { "<leader>or", "<cmd>Obsidian yesterday<CR>", desc = "Obsidian: Yesterday's note" },
    { "<leader>oy", "<cmd>Obsidian tomorrow<CR>", desc = "Obsidian: Tomorrow's note" },
    { "<leader>od", "<cmd>Obsidian dailies -2 1<CR>", desc = "Obsidian: Browse daily notes" },
    -- Quick access
    { "<leader>os", "<cmd>Obsidian search<CR>", desc = "Obsidian: Search" },
    { "<leader>oq", "<cmd>Obsidian quick_switch<CR>", desc = "Obsidian: Quick switch" },
    { "<leader>ow", "<cmd>Obsidian workspace<CR>", desc = "Obsidian: Switch workspace" },
  },
  opts = {
    legacy_commands = false,
    workspaces = {
      {
        name = "personal",
        path = "~/.notes/personal",
        strict = true,
      },
      {
        name = "work",
        path = "~/.notes/work",
        strict = true,
      },
    },

    daily_notes = {
      folder = "_daily",
    },

    note_id_func = function(title)
      return require("obsidian.builtin").title_id(title)
    end,

    callbacks = {
      -- Buffer-local mappings, only active inside Obsidian notes
      enter_note = function(note)
        -- Toggle checkbox (cycles through states: [ ] -> [x] -> etc.)
        -- Note: <CR> (smart_action) already toggles when cursor is ON a checkbox.
        -- This mapping works from anywhere on the line.
        vim.keymap.set("n", "<leader>oc", "<cmd>Obsidian toggle_checkbox<CR>", {
          buffer = true,
          desc = "Obsidian: Toggle checkbox",
        })
        vim.keymap.set("n", "<leader>on", "<cmd>Obsidian toc<CR>", {
          buffer = true,
          desc = "Obsidian: Table of contents",
        })
        vim.keymap.set("n", "<leader>ob", "<cmd>Obsidian backlinks<CR>", {
          buffer = true,
          desc = "Obsidian: Backlinks",
        })
        vim.keymap.set("n", "<leader>ol", "<cmd>Obsidian links<CR>", {
          buffer = true,
          desc = "Obsidian: Links",
        })
      end,
    },
  },
}
