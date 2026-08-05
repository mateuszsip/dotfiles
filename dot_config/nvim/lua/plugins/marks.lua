return {
  "chentoast/marks.nvim",
  event = "VeryLazy",
  opts = {
    -- whether to map keybindings or not. default true
    default_mappings = true,
    -- which builtin marks to show. default {}
    builtin_marks = { ".", "<", ">", "^" },
    -- whether movements cycle back to the beginning/end of buffer. default true
    cyclic = true,
    -- whether the signcolumn should be updated in real time. default true
    force_write_shada = false,
    -- how often (in ms) to redraw signcolumn. default 150
    refresh_interval = 150,
    -- sign priorities for each group of marks - builtin marks, lowercase marks , uppercase marks, bookmark groups.
    sign_priority = { lower = 10, upper = 15, builtin = 8, bookmark = 20 },
    -- excluded filetypes / buftypes
    excluded_filetypes = { "NvimTree", "neo-tree", "oil", "gitcommit", "snacks_picker_input" },
    excluded_buftypes = { "terminal", "nofile" },
    mappings = {},
  },
}
