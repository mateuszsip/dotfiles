return {
  "folke/sidekick.nvim",
  keys = {
    -- LazyVim's ai.sidekick extra binds these under <leader>a; drop them
    { "<leader>aa", false },
    { "<leader>as", false },
    { "<leader>ad", false },
    { "<leader>at", false },
    { "<leader>af", false },
    { "<leader>av", false },
    { "<leader>ap", false },
    {
      "<leader>aSc",
      function()
        require("sidekick.cli").toggle({ name = "claude", focus = true })
      end,
      desc = "Sidekick Toggle Claude",
    },
    {
      "<leader>aSo",
      function()
        require("sidekick.cli").toggle({ name = "opencode2", focus = true })
      end,
      desc = "Sidekick Toggle OpenCode 2",
    },
    {
      "<leader>aSg",
      function()
        require("sidekick.cli").toggle({ name = "antigravity", focus = true })
      end,
      desc = "Sidekick Toggle Antigravity",
    },
    {
      "<leader>aSp",
      function()
        require("sidekick.cli").toggle({ name = "pi", focus = true })
      end,
      desc = "Sidekick Toggle Pi",
    },
    {
      "<leader>aSP",
      function()
        require("sidekick.cli").prompt()
      end,
      mode = { "n", "x" },
      desc = "Sidekick Select Prompt",
    },
    {
      "<leader>aSb",
      function()
        local locs = require("haunt.sidekick").get_locations({ current_buffer = true })
        if locs and #locs > 0 then
          require("sidekick.cli").send({ msg = locs })
        else
          vim.notify("haunt.nvim: No bookmarks found in current buffer to send to Sidekick", vim.log.levels.WARN)
        end
      end,
      desc = "Sidekick: Send Buffer Haunt Bookmarks",
    },
    {
      "<leader>aSB",
      function()
        local locs = require("haunt.sidekick").get_locations()
        if locs and #locs > 0 then
          require("sidekick.cli").send({ msg = locs })
        else
          vim.notify("haunt.nvim: No bookmarks found to send to Sidekick", vim.log.levels.WARN)
        end
      end,
      desc = "Sidekick: Send All Haunt Bookmarks",
    },
    {
      "<leader>aSa",
      function()
        require("sidekick.cli").toggle()
      end,
      desc = "Sidekick Toggle CLI",
    },
    {
      "<leader>aSs",
      function()
        require("sidekick.cli").select()
      end,
      desc = "Select CLI",
    },
    {
      "<leader>aSd",
      function()
        require("sidekick.cli").close()
      end,
      desc = "Detach a CLI Session",
    },
    {
      "<leader>aSt",
      function()
        require("sidekick.cli").send({ msg = "{this}" })
      end,
      mode = { "x", "n" },
      desc = "Send This",
    },
    {
      "<leader>aSf",
      function()
        require("sidekick.cli").send({ msg = "{file}" })
      end,
      desc = "Send File",
    },
    {
      "<leader>aSv",
      function()
        require("sidekick.cli").send({ msg = "{selection}" })
      end,
      mode = { "x" },
      desc = "Send Visual Selection",
    },
    {
      "<A-n>",
      function()
        require("sidekick").nes_jump_or_apply()
      end,
      desc = "Goto/Apply Next Edit Suggestion",
    },
  },
  opts = {
    cli = {
      win = {
        -- disable default `<c-p>` terminal-mode prompt keymap;
        -- `<leader>aSP` already opens the prompt picker
        keys = { prompt = false },
        split = {
          width = 80,
        },
        float = {
          width = 0.75,
          height = 0.85,
        },
      },
      prompts = {
        haunt_all = function()
          return require("haunt.sidekick").get_locations()
        end,
        haunt_buffer = function()
          return require("haunt.sidekick").get_locations({ current_buffer = true })
        end,
      },
      tools = {
        antigravity = {
          cmd = { "agy" },
          is_proc = "\\<agy\\>",
          continue = { "--continue" },
        },
        opencode2 = {
          cmd = { "opencode2" },
          is_proc = "\\<opencode2\\>",
          continue = { "--continue" },
        },
      },
    },
  },
}
