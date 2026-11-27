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

      -- origami points the *current* window at the LSP foldexpr. On startup that
      -- is the CodeCompanion chat (utils/cc_chats opens it on VimEnter, before
      -- origami loads on VeryLazy), and the file's LSP has already attached, so
      -- origami's LspAttach handler missed it too: the file window kept LazyVim's
      -- treesitter foldexpr and autoFold's vim.lsp.foldclose("imports") had no
      -- LSP folds to close. Point every window showing the buffer instead.
      --
      -- Then close the autoFold kinds ourselves, once per buffer: origami's
      -- scheduled vim.lsp.foldclose() is a no-op until the buffer's LSP fold
      -- state exists, which only happens after vim.lsp.foldexpr() is first
      -- evaluated -- so evaluate it here and close on the next tick.
      local function autofold(buf, win)
        if vim.b[buf].lsp_autofolded then
          return
        end
        vim.b[buf].lsp_autofolded = true
        vim.api.nvim_win_call(win, function()
          vim.lsp.foldexpr(1)
        end)
        vim.schedule(function()
          if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
            for _, kind in ipairs(require("origami.config").config.autoFold.kinds) do
              pcall(vim.lsp.foldclose, kind, win)
            end
          end
        end)
      end

      local function use_lsp_folds(buf)
        if #vim.lsp.get_clients({ bufnr = buf, method = "textDocument/foldingRange" }) == 0 then
          return
        end
        local wins = vim.tbl_filter(function(win)
          return not vim.wo[win].diff
        end, vim.fn.win_findbuf(buf))
        for _, win in ipairs(wins) do
          vim.wo[win][0].foldmethod = "expr"
          vim.wo[win][0].foldexpr = "v:lua.vim.lsp.foldexpr()"
        end
        vim.b[buf].origami_folding_provider = "lsp"
        if wins[1] then
          autofold(buf, wins[1])
        end
      end
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        use_lsp_folds(buf)
      end
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("origami_all_windows", { clear = true }),
        callback = function(ctx)
          use_lsp_folds(ctx.buf)
        end,
      })
    end,
  },
}
