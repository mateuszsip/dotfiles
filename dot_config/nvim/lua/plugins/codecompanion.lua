-- Experimental: https://github.com/olimorris/codecompanion.nvim
-- Chat uses an ACP agent picked per machine: opencode2 when it's on PATH
-- (private laptop), otherwise Claude Code (work, subscription; needs
-- `npm i -g @agentclientprotocol/claude-agent-acp`). Inline/cmd interactions
-- only support HTTP adapters, so they stay on Copilot.
local chat_adapter = vim.fn.executable("opencode2") == 1 and "opencode" or "claude_code"

return {
  {
    "olimorris/codecompanion.nvim",
    version = "^19.0.0",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions", "CodeCompanionCmd", "CodeCompanionCodeReview" },
    keys = {
      { "<leader>zz", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "x" }, desc = "CodeCompanion Chat" },
      { "<leader>zn", ":CodeCompanionChat<cr>", mode = { "n", "x" }, desc = "CodeCompanion New Chat" },
      {
        "<leader>zt",
        function()
          -- /rename is HTTP-only, but Chat:set_title works for ACP chats too
          local cc = require("codecompanion")
          local chat = cc.buf_get_chat(0) or cc.last_chat()
          if not chat then
            return vim.notify("No CodeCompanion chat to rename", vim.log.levels.WARN)
          end
          vim.ui.input({ prompt = "Chat title: ", default = chat.title or "" }, function(input)
            if input and input ~= "" then
              chat:set_title(input)
            end
          end)
        end,
        desc = "CodeCompanion Rename Chat",
      },
      { "<leader>za", "<cmd>CodeCompanionActions<cr>", mode = { "n", "x" }, desc = "CodeCompanion Actions" },
      { "<leader>zi", ":CodeCompanion ", mode = { "n", "x" }, desc = "CodeCompanion Inline" },
      { "<leader>zs", "<cmd>CodeCompanionChat Add<cr>", mode = "x", desc = "CodeCompanion Add Selection" },
      { "<leader>zr", "<cmd>CodeCompanionCodeReview<cr>", desc = "CodeCompanion Review Agent Changes" },
      { "<leader>zR", "<cmd>CodeCompanionCodeReview Branch<cr>", desc = "CodeCompanion Review Branch" },
      { "<leader>zc", ":CodeCompanionCodeReview Comment<cr>", mode = { "n", "x" }, desc = "CodeCompanion Review Comment" },
    },
    opts = {
      adapters = {
        acp = {
          opencode = function()
            return require("codecompanion.adapters").extend("opencode", {
              commands = { default = { "opencode2", "acp" } },
            })
          end,
        },
      },
      interactions = {
        chat = { adapter = chat_adapter },
        inline = { adapter = "copilot" },
        cmd = { adapter = "copilot" },
      },
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = function(_, opts)
      opts.file_types = opts.file_types or { "markdown" }
      table.insert(opts.file_types, "codecompanion")
    end,
    ft = { "codecompanion" },
  },
  {
    "folke/which-key.nvim",
    opts = { spec = { { "<leader>z", group = "codecompanion", mode = { "n", "x" } } } },
  },
}
