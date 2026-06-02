return {
  "MeanderingProgrammer/render-markdown.nvim",
  opts = {
    file_types = { "markdown", "octo" },
    code = {
      width = "block",
      left_margin = 2,
      left_pad = 6,
      right_pad = 8,
      language_pad = 2,
      sign = false,
      border = "none",
      background_inset = 0,
      highlight_language = "RenderMarkdownCodeLang",
    },
    heading = {
      icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
    },
    pipe_table = {
      enabled = true,
    },
    anti_conceal = {
      enabled = false,
    },
    yaml = {
      enabled = false,
    },
    overrides = {
      filetype = {
        -- Octo buffers often contain GitHub-bot tables with mismatched column counts
        -- (e.g. Kyverno reports with 4-column headers but 6-column data rows).
        -- Rendered borders make misaligned tables harder to read; raw pipe text is clearer.
        octo = {
          pipe_table = { enabled = false },
        },
      },
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
  config = function(_, opts)
    require("render-markdown").setup(opts)
    local function fix_bullet_hl()
      local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
      vim.api.nvim_set_hl(0, "RenderMarkdownBullet", { fg = normal.fg, bg = "NONE" })
    end
    fix_bullet_hl()
    vim.api.nvim_create_autocmd("ColorScheme", { callback = fix_bullet_hl })
  end,
}
