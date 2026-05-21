return {
  "lewis6991/gitsigns.nvim",
  opts = {
    current_line_blame = true,
    current_line_blame_opts = {
      delay = 400,
      virt_text_pos = "eol",
    },
    on_attach = function(buffer)
      local gs = package.loaded.gitsigns

      local function map(mode, l, r, desc)
        vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
      end

      -- Toggle inline blame
      map("n", "<leader>ub", gs.toggle_current_line_blame, "Toggle Git Blame (inline)")
      -- Full blame window
      map("n", "<leader>ghB", gs.blame, "Git Blame (full)")
    end,
  },
}
