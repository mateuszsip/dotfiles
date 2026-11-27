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
    end,
  },
}
