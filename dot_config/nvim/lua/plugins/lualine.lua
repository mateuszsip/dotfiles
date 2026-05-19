return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.options = opts.options or {}
    opts.options.section_separators   = { left = "", right = "" }
    opts.options.component_separators = { left = "", right = "" }
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
    -- Add trouble breadcrumbs without kind icons (default {kind_icon} renders as grey boxes
    -- for YAML Object/Key kinds because TroubleIconObject uses a muted highlight)
    if LazyVim.has("trouble.nvim") then
      local trouble = require("trouble")
      local symbols = trouble.statusline({
        mode = "symbols",
        groups = {},
        title = false,
        filter = { range = true },
        format = "{symbol.name:Normal}",
        hl_group = "lualine_c_normal",
      })
      table.insert(opts.sections.lualine_c, {
        symbols and symbols.get,
        cond = function()
          return vim.b.trouble_lualine ~= false and symbols.has()
        end,
      })
    end

    return opts
  end,
}
