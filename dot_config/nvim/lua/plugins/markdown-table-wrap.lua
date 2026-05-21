return {
  {
    "ice345/markdown-table-wrap.nvim",
    ft = "markdown",
    keys = {
      { "<A-j>", "<cmd>MarkdownTablePrevCell<cr>", desc = "Prev table cell", ft = "markdown" },
      { "<A-k>", "<cmd>MarkdownTableNextRow<cr>", desc = "Next table row", ft = "markdown" },
      { "<A-l>", "<cmd>MarkdownTablePrevRow<cr>", desc = "Prev table row", ft = "markdown" },
      { "<A-;>", "<cmd>MarkdownTableNextCell<cr>", desc = "Next table cell", ft = "markdown" },
    },
    opts = {
      row_separator = true,
      max_col_width = 70,
      inline_viewport_scrolling = false,
      highlight_preset = "default",
      highlights = {
        border = { fg = "#B7B5AC" },
        inline = { link = "Normal" },
        header = { fg = "#403E3C", bold = true },
        code = { fg = "#878580" },
      },
    },
  },
}
