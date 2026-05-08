return {
  "MeanderingProgrammer/render-markdown.nvim",
  -- Use opts function so our overrides are applied AFTER the LazyVim extra's
  -- table opts (which set code/heading/checkbox). Table opts from multiple
  -- specs are merged in loading order; a function receives the final merged
  -- result and can override anything.
  opts = function(_, opts)
    -- Bullet icons: ambiguous-width Unicode (●, ○) causes visual issues when
    -- the terminal renders them wider than Neovim's strdisplaywidth count.
    -- With ambiwidth=double (set in options.lua), Neovim now agrees these are
    -- 2-cell wide, triggering overflow → inline+conceal mode in the markdown
    -- renderer, which correctly handles wide icons.
    opts.bullet = opts.bullet or {}
    opts.bullet.icons = { "•", "◦", "‣", "·" }

    -- Link icons: remove all inline link icons. They add visual clutter and
    -- misalign sub-list indentation when combined with bullet markers.
    opts.link = opts.link or {}
    opts.link.image = ""
    opts.link.email = ""
    opts.link.hyperlink = ""
    opts.link.wiki = opts.link.wiki or {}
    opts.link.wiki.icon = ""

    -- Disable YAML frontmatter bullet rendering. The YAML renderer always uses
    -- virt_text_pos='overlay' with no overflow fallback, so even with
    -- ambiwidth=double the icon width doesn't match the '-' marker, producing
    -- "•daily-notes" with no space. Raw "- tag" is cleaner.
    opts.yaml = { enabled = false }

    return opts
  end,
}
