-- Remove render-markdown link icons by hooking into state.config.on.initial.
--
-- Root cause: Updater.new() deep-copies state.config into self.config at
-- construction time. The initial BufEnter render (Updater A) captures the
-- original config (wiki.icon = '󱗖 '). Its async parse+display callback can
-- fire AFTER any forced re-render we schedule, overwriting the patched marks.
--
-- Fix: replace state.config.on.initial with a one-shot hook. render-markdown
-- calls on.initial() from inside Updater A's own render callback (after
-- Updater A's parse+display completes). At that point Updater A is DONE, so
-- a forced re-render (Updater B, with patched config) is guaranteed to be
-- the last writer for all rows.
vim.schedule(function()
  local ok, state = pcall(require, "render-markdown.state")
  if not ok or not state.config then
    return
  end

  local on_obj = state.config.on
  if not on_obj then
    return
  end

  local original_initial = on_obj.initial

  on_obj.initial = function(args)
    -- Restore FIRST to prevent re-triggering on our own forced re-render.
    on_obj.initial = original_initial

    -- Call original hook (usually a no-op).
    if type(original_initial) == "function" then
      original_initial(args)
    end

    -- Patch state.config link icons. All subsequent Config.new() calls will
    -- deep-copy from the patched state.config, so every new per-buffer config
    -- will have empty icons.
    local link = state.config.link
    if link then
      link.image = ""
      link.email = ""
      link.hyperlink = ""
      if link.wiki then
        link.wiki.icon = ""
      end
    end

    -- Disable YAML bullet rendering (overlay mode, no overflow fallback).
    if state.config.yaml then
      state.config.yaml.enabled = false
    end

    -- Clear the per-buffer config cache so Config.new() re-reads state.config.
    state.cache = {}

    -- Clear all rendered extmarks and the decorator cache, then force a fresh
    -- Updater B (with the patched config) for every visible markdown buffer.
    -- Because on.initial has already been restored above, Updater B's render
    -- will NOT re-trigger this hook.
    local ok_ui, ui = pcall(require, "render-markdown.core.ui")
    if ok_ui then
      ui.setup()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[buf].filetype == "markdown" then
          local win = vim.fn.bufwinid(buf)
          if win ~= -1 then
            ui.update(buf, win, "BufEnter", true)
          end
        end
      end
    end
  end
end)
