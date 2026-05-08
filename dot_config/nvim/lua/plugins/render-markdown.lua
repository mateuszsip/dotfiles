return {
  "MeanderingProgrammer/render-markdown.nvim",
  opts = function(_, opts)
    -- Remove all inline link icons. They misalign sub-list indentation and
    -- add visual clutter. Wiki links still have bracket concealing and link
    -- highlighting; only the prepended icon is removed.
    opts.link = opts.link or {}
    opts.link.image = ""
    opts.link.email = ""
    opts.link.hyperlink = ""
    opts.link.wiki = opts.link.wiki or {}
    opts.link.wiki.icon = ""

    -- YAML bullet renderer hardcodes virt_text_pos='overlay' with no
    -- overflow fallback, so icon width mismatches are unrecoverable at the
    -- config level. Disabling keeps raw "- tag" in frontmatter.
    opts.yaml = { enabled = false }

    return opts
  end,
}
