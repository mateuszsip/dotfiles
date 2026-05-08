return {
  "MeanderingProgrammer/render-markdown.nvim",
  opts = {
    -- Default bullet icons (●, ○, ◆, ◇) are Unicode "Ambiguous" width —
    -- some terminals render them as 2 cells wide. The YAML renderer always
    -- uses virt_text overlay with no overflow fallback, so a double-width
    -- icon consumes the space after the '-' marker giving "●daily-notes".
    -- Replace with "Narrow" width chars (U+2022, U+25E6, U+2023, U+00B7)
    -- which are always 1 cell wide, preserving the space in both YAML and
    -- markdown contexts.
    bullet = {
      icons = { "•", "◦", "‣", "·" },
    },
    link = {
      -- All link icon types disabled: the inline icons misalign sub-list
      -- item indentation and add visual clutter without enough benefit.
      image = "",
      email = "",
      hyperlink = "",
      wiki = {
        icon = "",
      },
    },
    -- Re-enable YAML rendering now that bullet icons are narrow.
    yaml = {
      enabled = true,
    },
  },
}
