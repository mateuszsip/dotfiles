-- Marp slide preview inside nvim (see utils/marp.lua). Hangs off image.nvim,
-- which does the rendering; the spec merges with the one in diagram.lua, so
-- image.nvim stays lazy and only loads when a preview opens.
return {
  "3rd/image.nvim",
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
      end,
    })
  end,
}
