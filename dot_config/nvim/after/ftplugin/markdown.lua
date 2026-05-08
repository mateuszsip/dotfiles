-- Remove render-markdown link icons.
--
-- Problem: Updater.new() captures self.config = state.get(buf) at construction
-- time (deep copy of state.config). The initial render on BufEnter creates
-- Updater A with the original config (wiki.icon = '󱗖 '). If we patch
-- state.config immediately and force a re-render (Updater B), both updaters
-- run concurrently via the decorator:schedule debounce (100ms). Updater A's
-- async parse callback fires last for some rows and overwrites B's 'X' marks
-- with the original '⊕' marks.
--
-- Fix: defer the patch past the debounce window (>100ms). By the time our
-- patch and forced re-render run, Updater A's render has already completed.
-- Our forced Updater B is then the last writer and wins for all rows.
vim.defer_fn(function()
  local ok, state = pcall(require, "render-markdown.state")
  if not ok or not state.config then
    return
  end

  -- Patch link icons directly on state.config.
  local link = state.config.link
  if link then
    link.image = ""
    link.email = ""
    link.hyperlink = ""
    if not link.wiki then
      link.wiki = {}
    end
    link.wiki.icon = ""
  end

  -- Disable YAML bullet rendering (overlay mode, no overflow fallback).
  local yaml = state.config.yaml
  if yaml then
    yaml.enabled = false
  end

  -- Wipe the per-buffer config cache so Config.new() re-reads state.config.
  state.cache = {}

  -- Clear all rendered extmarks and the decorator cache.
  local ok_ui, ui = pcall(require, "render-markdown.core.ui")
  if ok_ui then
    ui.setup()

    -- Force a fresh Updater (with the patched config) for every visible
    -- markdown buffer. This runs after Updater A has already completed, so
    -- our Updater B will be the last writer for all rows.
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.bo[buf].filetype == "markdown" then
        local win = vim.fn.bufwinid(buf)
        if win ~= -1 then
          ui.update(buf, win, "BufEnter", true)
        end
      end
    end
  end
end, 250)  -- 250ms > 100ms debounce; Updater A has completed by then
