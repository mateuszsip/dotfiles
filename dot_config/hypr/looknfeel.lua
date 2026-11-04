-- Personal look-and-feel overrides, applied after base/looknfeel.lua.
-- Migrated from looknfeel.conf

hl.config({
  decoration = {
    -- Rounded window corners
    rounding = 8,
  },

  -- Scrolling layout (workspace 3, see workspaces.lua): hovering a column
  -- that is only partly on screen must not yank the view. Soft (mouse)
  -- focus only follows when the column covers the whole monitor, so in
  -- practice hover never scrolls. Clicks and keyboard navigation are
  -- hard input and still scroll as before.
  scrolling = {
    follow_min_visible = 1.0,
  },

  -- Options kept from the original file, deliberately still commented out:
  --
  -- general = {
  --   gaps_in = 0,        -- no gaps between windows or borders
  --   gaps_out = 0,
  --   border_size = 0,
  --   layout = "master",  -- use the master layout instead of dwindle
  -- },
  --
  -- layout = {
  --   single_window_aspect_ratio = { 1, 1 },  -- avoid overly wide single-window layouts
  -- },
})
