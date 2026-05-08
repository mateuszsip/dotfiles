-- render-markdown link icon and YAML settings are patched directly in
-- after/ftplugin/markdown.lua, which runs after the plugin's config function
-- regardless of lazy.nvim spec merging order.
return {
  "MeanderingProgrammer/render-markdown.nvim",
}
