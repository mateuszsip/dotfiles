return {
  "MeanderingProgrammer/render-markdown.nvim",
  -- Use opts function so our overrides apply after the LazyVim extra's
  -- table opts (code/heading/checkbox). A function receives the already-merged
  -- opts and has the final say.
  opts = function(_, opts)
    -- Disable bullet icon rendering. The terminal renders ambiguous-width
    -- Unicode (●, ○, •, ◦, …) as 2 cells but Neovim's strdisplaywidth()
    -- returns 1 for them without ambiwidth=double, which conflicts with
    -- fillchars. The YAML renderer always uses overlay mode (no overflow
    -- fallback), so any icon wider than 1 cell visually consumes the space
    -- after the '-' marker. Disabling leaves the raw '-'/'*'/'+' markers,
    -- which always have correct spacing.
    opts.bullet = opts.bullet or {}
    opts.bullet.enabled = false

    -- Remove all inline link icons. They misalign sub-list indentation and
    -- add visual clutter. Wiki links still render with bracket concealing
    -- and link highlighting; only the prepended icon is removed.
    opts.link = opts.link or {}
    opts.link.image = ""
    opts.link.email = ""
    opts.link.hyperlink = ""
    opts.link.wiki = opts.link.wiki or {}
    opts.link.wiki.icon = ""

    -- YAML bullet renderer hardcodes overlay mode with no overflow fallback,
    -- so it can't be fixed at the config level. Raw "- tag" is cleaner.
    opts.yaml = { enabled = false }

    return opts
  end,
}
