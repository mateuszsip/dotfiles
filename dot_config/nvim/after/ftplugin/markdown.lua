-- Patch render-markdown link icons after the plugin has been configured.
--
-- render-markdown has two caches (state.cache for buf configs, core/ui cache
-- for decorators) plus live extmarks. The only safe way to clear all three
-- and trigger a fresh render is to call state.setup() with the patched config:
-- it resets both caches, clears all namespace extmarks via core/ui.setup(),
-- and resets the treesitter integration via core/ts.setup().
--
-- We deep-copy the *current* state.config so all LazyVim settings (code,
-- heading, checkbox…) are preserved and only the link icons are zeroed.
vim.schedule(function()
  local ok, state = pcall(require, "render-markdown.state")
  if not ok or not state.config then
    return
  end

  -- Preserve all existing config; only patch what we need.
  local config = vim.deepcopy(state.config)

  -- Remove all inline link icons.
  local link = config.link
  if link then
    link.image = ""
    link.email = ""
    link.hyperlink = ""
    if link.wiki then
      link.wiki.icon = ""
    end
  end

  -- Disable YAML bullet rendering (overlay mode, no overflow fallback).
  if config.yaml then
    config.yaml.enabled = false
  end

  -- Re-setup with patched config:
  --   • Updates state.config
  --   • Resets state.cache (per-buf config objects)
  --   • Calls core/ui.setup() → clears all extmarks + decorator cache
  --   • Calls core/ts.setup() → resets treesitter integration
  state.setup(config)

  -- Force an immediate re-render for every visible markdown buffer so the
  -- icons disappear without waiting for the next cursor movement.
  local ui_ok, ui = pcall(require, "render-markdown.core.ui")
  if ui_ok then
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.bo[buf].filetype == "markdown" then
        local win = vim.fn.bufwinid(buf)
        if win ~= -1 then
          ui.update(buf, win, "BufEnter", true)
        end
      end
    end
  end
end)
