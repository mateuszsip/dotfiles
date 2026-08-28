return {
  "atiladefreitas/dooing",
  cmd = { "Dooing", "DooingToggle", "DooingToday", "DooingAdd" },
  keys = {
    { "<leader>td", "<cmd>DooingToggle<cr>", desc = "Todos (Dooing)" },
    { "<leader>ta", "<cmd>DooingAdd<cr>", desc = "Add todo" },
    { "<leader>tt", "<cmd>DooingToday<cr>", desc = "Today's todos" },
  },
  opts = {
    -- defaults are sensible; see the Dooing README for everything
  },
}
