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
    opts = {
      diagnostics = {
        virtual_text = false,
      },
      servers = {
        ["*"] = {
          keys = {
            { "<leader>cl", false },
            { "<leader>ca", false },
            {
              "<leader>cL",
              function()
                Snacks.picker.lsp_config()
              end,
              desc = "Lsp Info",
            },
          },
        },
        phpantom_lsp = {
          -- Prefer composer.json over .git as root marker — monorepos have
          -- per-service composer.json files that define the correct project root.
          root_markers = { "composer.json", ".phpantom.toml", ".git" },
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
