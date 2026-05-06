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
          kinds = { "comment", "imports" },
        },
        foldKeymaps = {
          setup = false, -- mapped in keymaps.lua to match j=left, ;=right layout
        },
      })

      -- Override foldexpr for PHP after origami sets it, and auto-close imports.
      -- vim.schedule defers until after origami's own FileType autocmd has run.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "php",
        callback = function()
          vim.schedule(function()
            vim.wo.foldexpr = "v:lua.require('config.php_folds').foldexpr(v:lnum)"
            require("config.php_folds").auto_close_imports()
          end)
        end,
      })
    end,
  },
}
