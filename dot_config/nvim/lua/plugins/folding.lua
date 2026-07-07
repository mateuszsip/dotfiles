return {
  {
    "chrisgrieser/nvim-origami",
    event = "VeryLazy",
    init = function()
      vim.opt.foldlevel = 99
      vim.opt.foldlevelstart = 99
    end,
    config = function()
      require("origami").setup({
        useLspFoldsWithTreesitterFallback = { enabled = true },
        pauseFoldsOnSearch = true,
        foldtext = {
          lineCount = { template = "󰁅 %d lines", hlgroup = "OrigamiFold" },
        },
        autoFold = {
          enabled = true,
          kinds = { "imports" },
        },
        foldKeymaps = {
          setup = false, -- mapped in keymaps.lua to match j=left, ;=right layout
        },
      })

      -- Override foldexpr for PHP with our own import-grouping expr, and
      -- auto-close imports. phpantom_lsp advertises foldingRange but does NOT
      -- fold the `use` import block, so we cannot rely on origami's LSP folds.
      --
      -- origami swaps foldexpr to `vim.lsp.foldexpr()` on LspAttach, which fires
      -- asynchronously *after* FileType. So we must re-apply on LspAttach too,
      -- otherwise the LSP clobbers our expr the moment phpantom_lsp attaches.
      local function apply_php_folds()
        vim.wo.foldmethod = "expr"
        vim.wo.foldexpr = "v:lua.require('config.php_folds').foldexpr(v:lnum)"
        require("config.php_folds").auto_close_imports()
      end

      -- FileType handles the no-LSP case (treesitter fallback path).
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "php",
        callback = function()
          vim.schedule(apply_php_folds)
        end,
      })

      -- LspAttach re-applies after origami's own LspAttach handler has run.
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ctx)
          if vim.bo[ctx.buf].filetype ~= "php" then
            return
          end
          vim.schedule(apply_php_folds)
        end,
      })
    end,
  },
}
