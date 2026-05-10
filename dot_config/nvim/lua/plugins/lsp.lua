return {
  {
    "mfussenegger/nvim-lint",
    keys = {
      {
        "<leader>cl",
        function()
          require("lint").try_lint()
        end,
        desc = "Lint",
      },
    },
    opts = {
      linters_by_ft = {
        php = { "phpstan" },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        php = { "php_cs_fixer" },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    init = function()
      -- Workaround for Neovim 0.12 changetracking group mismatch / sync assertion failures.
      -- Patch _changetracking.init so sync_kind is forced to Full before grouping runs.
      local ct = require("vim.lsp._changetracking")
      local orig_init = ct.init
      ct.init = function(client, bufnr)
        if client.server_capabilities then
          client.server_capabilities.textDocumentSync = vim.lsp.protocol.TextDocumentSyncKind.Full
        end
        orig_init(client, bufnr)
      end
    end,
    opts = {
      servers = {
        ["*"] = {
          keys = {
            { "<leader>cl", false },
            { "<leader>cL", function() Snacks.picker.lsp_config() end, desc = "Lsp Info" },
          },
        },
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = {
                globals = { "vim" },
              },
            },
          },
        },
      },
    },
  },
}
