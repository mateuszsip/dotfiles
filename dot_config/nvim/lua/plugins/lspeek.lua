return {
  "r4ppz/lspeek.nvim",
  keys = {
    { "gt", function() require("lspeek").peek_type_definition() end, desc = "Peek type definition" },
    { "gT", function() require("lspeek").peek_definition() end,      desc = "Peek definition" },
  },
  opts = {
    window = { width = 100, height = 25 },
  },
}
