return {
  "akinsho/bufferline.nvim",
  opts = {
    options = {
      separator_style = "thin",
      indicator = { style = "underline" },
    },
  },
  config = function(_, opts)
    local get_color = require("bufferline.colors").get_color
    local nbg = get_color({ name = "Normal", attribute = "bg" })
    local cfg = get_color({ name = "Comment", attribute = "fg" })
    local sep = "#CECDC3"

    -- Every group gets Normal bg so the tab bar blends with the editor.
    -- Per-group fg/sp overrides are left to defaults (only bg is forced).
    local bg_groups = {
      "fill", "background", "buffer", "tab", "tab_close",
      "close_button", "close_button_visible", "close_button_selected",
      "buffer_visible", "buffer_selected",
      "tab_selected",
      "numbers", "numbers_visible", "numbers_selected",
      "modified", "modified_visible", "modified_selected",
      "duplicate", "duplicate_visible", "duplicate_selected",
      "pick", "pick_visible", "pick_selected",
      "indicator_visible", "indicator_selected",
      "trunc_marker",
      "diagnostic", "diagnostic_visible", "diagnostic_selected",
      "hint",  "hint_visible",  "hint_selected",
      "hint_diagnostic",  "hint_diagnostic_visible",  "hint_diagnostic_selected",
      "info",  "info_visible",  "info_selected",
      "info_diagnostic",  "info_diagnostic_visible",  "info_diagnostic_selected",
      "warning",  "warning_visible",  "warning_selected",
      "warning_diagnostic",  "warning_diagnostic_visible",  "warning_diagnostic_selected",
      "error",  "error_visible",  "error_selected",
      "error_diagnostic",  "error_diagnostic_visible",  "error_diagnostic_selected",
    }
    local hl = { background = { bg = nbg, fg = cfg } }
    for _, name in ipairs(bg_groups) do
      hl[name] = vim.tbl_extend("keep", hl[name] or {}, { bg = nbg })
    end
    hl.separator          = { fg = sep, bg = nbg }
    hl.separator_visible  = { fg = sep, bg = nbg }
    hl.separator_selected = { fg = sep, bg = nbg }

    opts.highlights = vim.tbl_deep_extend("force", hl, opts.highlights or {})
    require("bufferline").setup(opts)

    vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
      callback = function()
        vim.schedule(function() pcall(nvim_bufferline) end)
      end,
    })
  end,
}
