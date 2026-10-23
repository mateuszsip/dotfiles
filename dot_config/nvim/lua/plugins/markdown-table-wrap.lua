return {
  {
    "ice345/markdown-table-wrap.nvim",
    ft = "markdown",
    keys = {
      -- Cell navigation. Also registered for the float's own buffer
      -- (filetype markdown-table-wrap), otherwise the keys would be dead
      -- while the float has focus.
      {
        "<A-j>",
        "<cmd>MarkdownTablePrevCell<cr>",
        desc = "Prev table cell",
        ft = { "markdown", "markdown-table-wrap" },
      },
      {
        "<A-k>",
        "<cmd>MarkdownTableNextRow<cr>",
        desc = "Next table row",
        ft = { "markdown", "markdown-table-wrap" },
      },
      {
        "<A-l>",
        "<cmd>MarkdownTablePrevRow<cr>",
        desc = "Prev table row",
        ft = { "markdown", "markdown-table-wrap" },
      },
      {
        "<A-;>",
        "<cmd>MarkdownTableNextCell<cr>",
        desc = "Next table cell",
        ft = { "markdown", "markdown-table-wrap" },
      },
      {
        "<leader>mf",
        "<cmd>MarkdownTableTogglePreview<cr>",
        desc = "Markdown: Float table",
        ft = { "markdown", "markdown-table-wrap" },
      },
    },
    opts = {
      -- Show the table in a floating window instead of the full-document
      -- Reader, which used to replace the buffer as soon as it contained a
      -- table. A float cannot be the automatic mode: refresh_auto has no
      -- float branch and would fall through to inline rendering, so auto
      -- preview stays off and <leader>mf opens the float on demand
      -- (q/<Esc> closes it and returns to the same logical cell).
      preview_mode = "float",
      auto_preview = false,
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
