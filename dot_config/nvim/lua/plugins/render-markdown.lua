return {
  "MeanderingProgrammer/render-markdown.nvim",
  -- opts = function approach doesn't reliably win against the LazyVim
  -- extra's config function. Overriding config directly is the only
  -- guarantee. We replicate the essential parts of LazyVim's config here.
  config = function(_, opts)
    -- Remove all inline link icons. The globe icon before wiki/hyperlinks
    -- misaligns sub-list indentation and adds visual clutter.
    opts.link = opts.link or {}
    opts.link.image = ""
    opts.link.email = ""
    opts.link.hyperlink = ""
    opts.link.wiki = opts.link.wiki or {}
    opts.link.wiki.icon = ""

    -- YAML bullet renderer hardcodes overlay mode with no overflow fallback;
    -- any icon wider than '-' (1 cell) misaligns. Raw "- tag" is cleaner.
    opts.yaml = { enabled = false }

    require("render-markdown").setup(opts)

    -- Replicate LazyVim extra: register Snacks toggle for <leader>um
    Snacks.toggle({
      name = "Render Markdown",
      get = require("render-markdown").get,
      set = require("render-markdown").set,
    }):map("<leader>um")
  end,
}
