return {
  "MeanderingProgrammer/render-markdown.nvim",
  opts = {
    file_types = { "markdown", "octo" },
    code = {
      left_pad = 2,
      right_pad = 2,
    },
    html = {
      enabled = true,
      tag = {
        -- conceal <h4> … </h4> HTML heading tags used in Octo check-run output
        h4 = { icon = "▸ " },
      },
    },
  },
  ft = { "markdown", "octo" },
}
