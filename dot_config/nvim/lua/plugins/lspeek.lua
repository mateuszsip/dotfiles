return {
  "r4ppz/lspeek.nvim",
  keys = {
    -- gz/gZ, not the plugin's default gD (atlas owns gD) and not gt/gT
    -- (built-in tab switching; diffview and neogit open tabs).
    { "gz", function() require("lspeek").peek_definition() end, desc = "Peek definition" },
    { "gZ", function() require("lspeek").peek_type_definition() end, desc = "Peek type definition" },
  },
  opts = {
    window = { width = 100, height = 25 },
  },
}
