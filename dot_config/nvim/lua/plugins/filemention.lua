return {
  {
    "not-manu/filemention.nvim",
    event = "InsertEnter",
    opts = {},
  },
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      opts.sources.default = opts.sources.default or {}
      table.insert(opts.sources.default, "filemention")
      opts.sources.providers = opts.sources.providers or {}
      opts.sources.providers.filemention = {
        name = "filemention",
        module = "filemention.sources.blink",
      }
    end,
  },
}
