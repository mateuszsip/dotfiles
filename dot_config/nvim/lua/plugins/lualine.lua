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
    -- Add trouble breadcrumbs as plain text so lualine paints them with lualine_c_normal.
    -- Trouble wraps each segment in %#HL#text%* statusline codes; the %* resets to the
    -- global StatusLine group (not lualine's section color), causing grey-box artifacts
    -- between items. Stripping HL codes avoids the background mismatch entirely.
    if LazyVim.has("trouble.nvim") then
      local trouble = require("trouble")
      local symbols = trouble.statusline({
        mode = "symbols",
        groups = {},
        title = false,
        filter = { range = true },
        format = "{kind_icon}{symbol.name:Normal}",
        hl_group = "lualine_c_normal",
      })
      local function plain_symbols()
        local s = symbols.get()
        if not s then return s end
        return s:gsub("%%#[^#]*#", ""):gsub("%%%*", "")
      end
      table.insert(opts.sections.lualine_c, {
        plain_symbols,
        cond = function()
          return vim.b.trouble_lualine ~= false and symbols.has()
        end,
      })
    end

    return opts
  end,
}
