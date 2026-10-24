-- Personal look-and-feel overrides, applied after base/looknfeel.lua.
-- Migrated from looknfeel.conf; that file stays authoritative until phase 7.

hl.config({
  decoration = {
    -- Rounded window corners
    rounding = 8,
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
