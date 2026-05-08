-- Remove render-markdown link icons via the on.initial hook.
--
-- When on.initial fires (from inside Updater A's render callback), A's
-- treesitter context is still marked "in progress". Calling ui.update()
-- immediately would create Updater B whose Context.new() detects the in-
-- progress flag and returns nil, causing B's render to be skipped entirely.
-- A's display() then adds '⊕' marks after the hook returns.
--
-- Fix: defer the ui.setup()+ui.update() via vim.schedule so it runs AFTER
-- A's callback fully returns and the "in progress" flag is cleared.
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
    -- Restore immediately to prevent any re-trigger.
    on_obj.initial = original_initial
    if type(original_initial) == "function" then
      original_initial(args)
    end

    -- Patch state.config so every future per-buffer config has empty icons.
    local link = state.config.link
    if link then
      link.image = ""
      link.email = ""
      link.hyperlink = ""
      if link.wiki then
        link.wiki.icon = ""
      end
    end
    if state.config.yaml then
      state.config.yaml.enabled = false
    end
    state.cache = {}

    -- Defer the actual clearing and re-render until AFTER Updater A's
    -- callback fully returns (so the treesitter "in progress" flag clears).
    vim.schedule(function()
      local ok_ui, ui = pcall(require, "render-markdown.core.ui")
      if not ok_ui then
        return
      end
      -- Clear all namespace extmarks and reset the decorator cache.
      ui.setup()
      -- Force a fresh Updater B (with patched config) for every visible
      -- markdown buffer. Context.new() will succeed now that A is done.
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[buf].filetype == "markdown" then
          local win = vim.fn.bufwinid(buf)
          if win ~= -1 then
            ui.update(buf, win, "BufEnter", true)
          end
        end
      end
    end)
  end
end)
