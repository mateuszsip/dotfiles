return {
  "atiladefreitas/dooing",
  cmd = { "Dooing", "DooingToggle", "DooingToday", "DooingAdd" },
  -- No spec keys: neotest owns the <leader>t prefix and would overwrite them.
  -- Reachable via the :Dooing commands.
  opts = {
    -- defaults are sensible; see the Dooing README for everything
  },
}
