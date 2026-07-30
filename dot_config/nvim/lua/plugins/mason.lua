-- Tools / formatters / linters only.
-- LSP servers are installed via nvim-lspconfig `opts.servers` (see lsp.lua):
-- LazyVim auto-installs + enables any enabled server whose mason package
-- exists. Keeping LSP servers out of this list avoids two concurrent
-- `p:install()` loops racing on the same package and throwing
-- "Package is already installing." at startup.
--
-- copilot-language-server is NOT here: LazyVim's copilot-native extra enables
-- the lspconfig `copilot` server, so mason-lspconfig already installs it.
return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "cmakelang",
        "cmakelint",
        "hadolint",
        "markdown-toc",
        "markdownlint",
        "php-cs-fixer",
        "phpcs",
        "shellcheck",
        "shfmt",
        "sqlfluff",
        "stylua",
        "twig-cs-fixer",
        "twigcs",
      },
    },
  },
}