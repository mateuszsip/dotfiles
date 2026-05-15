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
        markdown = { "markdownlint" },
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
      -- Phpactor advertises Incremental sync but has issues with Nvim 0.12's changetracking.
      -- Force Full sync by patching only the `change` field, preserving `openClose` so that
      -- didOpen is still sent (replacing the whole textDocumentSync object breaks openClose).
      local ct = require("vim.lsp._changetracking")
      local orig_init = ct.init
      ct.init = function(client, bufnr)
        local caps = client.server_capabilities
        if caps then
          local tds = caps.textDocumentSync
          if type(tds) == "table" then
            tds.change = vim.lsp.protocol.TextDocumentSyncKind.Full
          end
        end
        orig_init(client, bufnr)
      end
    end,
    opts = {
      diagnostics = {
        virtual_text = false,
      },
      servers = {
        ["*"] = {
          keys = {
            { "<leader>cl", false },
            {
              "<leader>cL",
              function()
                Snacks.picker.lsp_config()
              end,
              desc = "Lsp Info",
            },
          },
        },
        phpactor = {
          -- nvim-lspconfig changed root_markers to prefer .git over composer.json,
          -- which breaks monorepos where each service has its own composer.json.
          root_markers = { "composer.json", ".phpactor.json", ".phpactor.yml", ".git" },
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
