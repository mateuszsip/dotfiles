return {
  "obsidian-nvim/obsidian.nvim",
  version = "*", -- recommended, use latest release instead of latest commit
  ft = "markdown",
  keys = {
    -- Daily notes (global, work from any buffer)
    { "<leader>odt", "<cmd>Obsidian today<CR>", desc = "Obsidian: Today's note" },
    { "<leader>odr", "<cmd>Obsidian yesterday<CR>", desc = "Obsidian: Yesterday's note" },
    { "<leader>ody", "<cmd>Obsidian tomorrow<CR>", desc = "Obsidian: Tomorrow's note" },
    { "<leader>od", "<cmd>Obsidian dailies -3 2<CR>", desc = "Obsidian: Browse daily notes" },
    { "<leader>ode", "<cmd>Obsidian dailies -3 2<CR>", desc = "Obsidian: Browse daily notes" },
    -- Quick access
    { "<leader>ot", "<cmd>Obsidian tags<CR>", desc = "Obsidian: Tags" },
    { "<leader>os", "<cmd>Obsidian search<CR>", desc = "Obsidian: Search" },
    { "<leader>oq", "<cmd>Obsidian quick_switch<CR>", desc = "Obsidian: Quick switch" },
    { "<leader>oww", "<cmd>Obsidian workspace work<CR>", desc = "Obsidian: Work workspace" },
    { "<leader>owp", "<cmd>Obsidian workspace personal<CR>", desc = "Obsidian: Personal workspace" },
    { "<leader>owW", "<cmd>Obsidian workspace<CR>", desc = "Obsidian: Pick workspace" },
    {
      "<leader>oT",
      function()
        local ws = Obsidian.workspace
        if ws then
          vim.cmd("e " .. tostring(ws.path) .. "/_todo.md")
        else
          vim.notify("No active Obsidian workspace", vim.log.levels.WARN)
        end
      end,
      desc = "Obsidian: Todo",
    },
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

    link = {
      auto_update = true,
    },

    note_id_func = function(title)
      return require("obsidian.builtin").title_id(title)
    end,

    callbacks = {
      -- Buffer-local mappings, only active inside Obsidian notes
      enter_note = function()
        -- Toggle checkbox (cycles through states: [ ] -> [x] -> etc.)
        -- Note: <CR> (smart_action) already toggles when cursor is ON a checkbox.
        -- This mapping works from anywhere on the line.
        vim.keymap.set("n", "<leader>oc", "<cmd>Obsidian toggle_checkbox<CR>", {
          buffer = true,
          desc = "Obsidian: Toggle checkbox",
        })
        -- Set specific checkbox state directly
        local actions = require("obsidian.actions")
        vim.keymap.set("n", "<leader>o<space>", function()
          actions.set_checkbox(" ")
        end, {
          buffer = true,
          desc = "Obsidian: Checkbox unchecked [ ]",
        })
        vim.keymap.set("n", "<leader>ox", function()
          actions.set_checkbox("x")
        end, {
          buffer = true,
          desc = "Obsidian: Checkbox done [x]",
        })
        vim.keymap.set("n", "<leader>o~", function()
          actions.set_checkbox("~")
        end, {
          buffer = true,
          desc = "Obsidian: Checkbox in progress [~]",
        })
        vim.keymap.set("n", "<leader>o!", function()
          actions.set_checkbox("!")
        end, {
          buffer = true,
          desc = "Obsidian: Checkbox important [!]",
        })
        vim.keymap.set("n", "<leader>o>", function()
          actions.set_checkbox(">")
        end, {
          buffer = true,
          desc = "Obsidian: Checkbox forwarded [>]",
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
        vim.keymap.set("v", "<leader>ol", "<cmd>Obsidian link<CR>", {
          buffer = true,
          desc = "Obsidian: Link selection to existing note",
        })
        vim.keymap.set("v", "<leader>oL", "<cmd>Obsidian link_new<CR>", {
          buffer = true,
          desc = "Obsidian: Link new note from selection",
        })
      end,
    },
  },
}
