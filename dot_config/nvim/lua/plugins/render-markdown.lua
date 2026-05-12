return {
  "MeanderingProgrammer/render-markdown.nvim",
  opts = {
    file_types = { "markdown", "octo" },
    html = {
      enabled = true,
      tag = {
        -- conceal <h4> … </h4> HTML heading tags used in Octo check-run output
        h4 = { icon = "▸ " },
      },
    },
  },
  ft = { "markdown", "octo" },
  init = function()
    -- no octo treesitter parser exists; use markdown parser for octo buffers
    vim.treesitter.language.register("markdown", "octo")
  end,
}
