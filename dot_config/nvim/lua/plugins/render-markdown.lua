return {
  "MeanderingProgrammer/render-markdown.nvim",
  opts = {
    link = {
      -- Remove wiki link icon to fix indentation alignment in lists.
      -- The globe icon adds width that misaligns sub-list items.
      wiki = {
        icon = "",
      },
    },
    -- Disable bullet rendering in YAML frontmatter. The overlay icon
    -- stacks visually with indent guides and doesn't suit frontmatter context.
    yaml = {
      enabled = false,
    },
  },
}
