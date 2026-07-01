return {
  "nvim-mini/mini.visits",
  lazy = true,
  keys = {
    {
      "<leader>fv",
      function()
        local visits = require("mini.visits")
        visits.select_path(nil, { sort = visits.gen_sort.default({ recency_weight = 0.5 }) })
      end,
      desc = "Visits (cwd)",
    },
    {
      "<leader>fa",
      function()
        local visits = require("mini.visits")
        visits.select_path("", { sort = visits.gen_sort.default({ recency_weight = 0.5 }) })
      end,
      desc = "Visits (all)",
    },
  },
  opts = {},
}