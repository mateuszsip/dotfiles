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
    -- bullet.lua uses virt_text_pos='overlay' without hl_mode, so bg=NONE falls back
    -- to Normal.bg (paper white) instead of inheriting the line's bg (code block beige).
    -- Replace Bullet.marker with an identical version that adds hl_mode='combine'.
    local Bullet = require("render-markdown.render.markdown.bullet")
    local str = require("render-markdown.lib.str")
    Bullet.marker = function(self)
      local icon = self.data.icon
      local highlight = self.data.highlight
      if not icon or not highlight then return end
      local node = self.data.marker
      local text = str.pad(str.spaces("start", node.text)) .. icon
      local overflow = str.width(text) > str.width(node.text)
      self.marks:over(self.config, "bullet", node, {
        virt_text = { { text, highlight } },
        virt_text_pos = overflow and "inline" or "overlay",
        conceal = overflow and "" or nil,
        hl_mode = "blend",
      })
    end
  end,
}
