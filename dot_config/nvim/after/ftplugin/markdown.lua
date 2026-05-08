-- Patch render-markdown's live config to remove link icons.
--
-- All opts-based approaches (opts = function, config override) lose against
-- lazy.nvim's spec merging order when the LazyVim extra owns the config
-- function. Instead, we schedule a direct state patch to run AFTER
-- render-markdown has already been set up and rendered the buffer.
vim.schedule(function()
  local ok, state = pcall(require, "render-markdown.state")
  if not ok or not state.config then
    return
  end

  local link = state.config.link
  if not link then
    return
  end

  -- Clear all inline link icons.
  link.image = ""
  link.email = ""
  link.hyperlink = ""
  if link.wiki then
    link.wiki.icon = ""
  end

  -- Disable YAML bullet overlay (hardcodes virt_text_pos='overlay' with no
  -- overflow fallback; any wide icon eats the space after the '-' marker).
  if state.config.yaml then
    state.config.yaml.enabled = false
  end

  -- Clear per-buffer config cache so the next render picks up the patched
  -- state.config instead of the stale cached per-buffer config objects.
  state.cache = {}

  -- Re-attach treesitter so open buffers re-render with the new config.
  state.attach()
end)
