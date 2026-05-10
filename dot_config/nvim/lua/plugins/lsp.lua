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
