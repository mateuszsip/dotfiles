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

    -- tree-sitter-markdown bug: creates phantom list_item siblings (NOT children)
    -- of fenced_code_block for any '-' line inside a code fence. The parent()
    -- walk can't find fenced_code_block because the nodes are siblings, not nested.
    -- Instead, run a position check: skip any bullet whose row falls inside a
    -- fenced_code_block range in the markdown tree.
    local _code_query = nil
    local function in_code_fence(buf, row)
      local parser = vim.treesitter.get_parser(buf, "markdown")
      if not parser then return false end
      _code_query = _code_query
        or vim.treesitter.query.parse("markdown", "(fenced_code_block) @block")
      for _, tree in ipairs(parser:parse(false) or {}) do
        for _, node in _code_query:iter_captures(tree:root(), buf) do
          local sr, _, er = node:range()
          if row > sr and row < er then return true end
        end
      end
      return false
    end

    local Bullet = require("render-markdown.render.markdown.bullet")
    local str = require("render-markdown.lib.str")
    Bullet.marker = function(self)
      if in_code_fence(self.context.buf, self.node.start_row) then return end
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
      })
    end
  end,
}
