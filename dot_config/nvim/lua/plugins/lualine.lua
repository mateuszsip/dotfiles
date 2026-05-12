return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.options = opts.options or {}
    opts.options.theme = (function()
      local auto = require("lualine.themes.auto")
      local hl = vim.api.nvim_get_hl(0, { name = "Normal" })
      local bg = hl.bg and string.format("#%06x", hl.bg) or "#FFFCF0"
      for _, mode in ipairs({ "normal", "insert", "visual", "replace", "command", "inactive" }) do
        local m = auto[mode] or {}
        for _, section in ipairs({ "b", "c", "x", "y", "z" }) do
          m[section] = m[section] or {}
          m[section].bg = bg
        end
        auto[mode] = m
      end
      return auto
    end)()
    return opts
  end,
}
