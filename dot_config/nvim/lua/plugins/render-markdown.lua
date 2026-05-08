return {
  "MeanderingProgrammer/render-markdown.nvim",
  opts = function(_, opts)
    -- Bullet icons: append a trailing space to each icon so the total
    -- strdisplaywidth (icon + space = 2) exceeds strdisplaywidth("-") = 1.
    -- This triggers the overflow branch in the markdown bullet renderer,
    -- which uses virt_text_pos='inline' + conceal='', correctly inserting
    -- the icon without relying on terminal/Neovim width agreement for
    -- the bullet character itself. Without this, overlay mode is used and
    -- terminals that render ●/○ as 2-cell-wide visually consume the space
    -- after the list marker, producing "●item" instead of "● item".
    -- The trailing space in the icon also replaces the space that follows
    -- the concealed "-" marker, so spacing stays correct.
    opts.bullet = opts.bullet or {}
    opts.bullet.icons = { "● ", "○ ", "◆ ", "◇ " }

    -- Link icons: remove all inline link icons.
    opts.link = opts.link or {}
    opts.link.image = ""
    opts.link.email = ""
    opts.link.hyperlink = ""
    opts.link.wiki = opts.link.wiki or {}
    opts.link.wiki.icon = ""

    -- YAML bullet renderer hardcodes overlay mode with no overflow fallback.
    -- Raw "- tag" is cleaner than a misaligned icon.
    opts.yaml = { enabled = false }

    return opts
  end,
}
