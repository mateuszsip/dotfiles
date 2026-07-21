return {
  "kunkka19xx/present.nvim",
  cmd = "PresentStart",
  ft = "markdown",
  keys = {
    {
      "<leader>Ps",
      "<cmd>PresentStart<CR>",
      desc = "Start Presentation",
    },
  },
  opts = function(_, opts)
    local create = require("present").create_system_executor
    opts.executors = vim.tbl_deep_extend("force", opts.executors or {}, {
      php = create("php"),
      bash = create("bash"),
      sh = create("sh"),
    })
  end,
  config = function(_, opts)
    require("present").setup(opts)
  end,
}