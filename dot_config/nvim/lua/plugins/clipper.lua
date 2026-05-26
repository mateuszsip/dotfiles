return {
  "jbuck95/web-clipper.nvim",
  build = "npm install --prefix bin",
  config = function()
    require("web-clipper").setup({
      vault_dir = "~/.notes/clipper",
      sites = {},
    })
    vim.keymap.set("n", "<leader>mw", require("web-clipper").clip, { desc = "Web clip" })
  end,
}
