-- Remove render-markdown link icons after the plugin has configured itself.
--
-- We modify state.config directly (not through a deep-copy + state.setup)
-- to avoid state.setup() calling core.ts.setup(), which re-registers FileType
-- autocmds and may have unintended interactions. We only clear the parts we
-- need: the per-buffer config cache and the rendered extmarks.
vim.schedule(function()
  local ok, state = pcall(require, "render-markdown.state")
  if not ok or not state.config then
    return
  end

  -- Patch link config.
  local link = state.config.link
  if link then
    -- Direct fields.
    link.image = ""
    link.email = ""
    link.hyperlink = ""

    -- Nested wiki config - initialise if somehow absent.
    if not link.wiki then
      link.wiki = {}
    end
    link.wiki.icon = "X"  -- temporary: confirm render path before using ""
  end

  -- Disable YAML bullet rendering (overlay mode baked in, no config fix).
  local yaml = state.config.yaml
  if yaml then
    yaml.enabled = false
  end

  -- Verify the patch landed (writes to Neovim messages on first open).
  local wiki_icon = link and link.wiki and vim.inspect(link.wiki.icon) or "n/a"
  local hyper     = link and vim.inspect(link.hyperlink)              or "n/a"
  vim.notify(
    ("render-markdown patch: hyperlink=%s wiki.icon=%s"):format(hyper, wiki_icon),
    vim.log.levels.DEBUG
  )

  -- Wipe the per-buffer config cache so Config.new() re-reads state.config.
  state.cache = {}

  -- Clear all rendered extmarks and the decorator cache without going through
  -- state.setup() (which would call core.ts.setup() and re-register autocmds).
  local ok_ui, ui = pcall(require, "render-markdown.core.ui")
  if ok_ui then
    ui.setup()  -- clears M.ns extmarks in all bufs + resets M.cache

    -- Trigger immediate re-render for every visible markdown buffer.
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
