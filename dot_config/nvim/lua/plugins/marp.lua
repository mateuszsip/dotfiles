-- Marp slide preview inside nvim (see utils/marp.lua). Hangs off image.nvim,
-- which does the rendering; the spec merges with the one in diagram.lua, so
-- image.nvim stays lazy and only loads when a preview opens.
return {
  "3rd/image.nvim",
  -- Terminal graphics sit above all text, so floats (pickers, hovers,
  -- which-key) can't cover an image. Hide images while a float overlaps
  -- their window instead; they come back when it closes. Also applies to
  -- the diagram preview (opts merge with diagram.lua's image.nvim spec).
  opts = { window_overlap_clear_enabled = true },
  init = function()
    vim.api.nvim_create_user_command("MarpPreview", function()
      require("utils.marp").toggle()
    end, { desc = "Toggle Marp slide preview" })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "markdown",
      group = vim.api.nvim_create_augroup("MarpPreviewKeys", { clear = true }),
      callback = function(ev)
        vim.keymap.set("n", "<leader>mp", function()
          require("utils.marp").toggle(ev.buf)
        end, { buffer = ev.buf, desc = "Marp: toggle slide preview" })
        vim.keymap.set("n", "<leader>mP", function()
          require("utils.marp").browser(ev.buf)
        end, { buffer = ev.buf, desc = "Marp: toggle browser preview" })
        -- ]] / [[ / <leader>ms slide navigation, only in decks (`marp: true`)
        -- so plain markdown keeps LazyVim's ]] / [[ reference jumps.
        local marp = require("utils.marp")
        if marp.is_deck(ev.buf) then
          marp.attach(ev.buf)
        end
      end,
    })
  end,
}
