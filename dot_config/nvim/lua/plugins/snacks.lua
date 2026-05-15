local function buf_dir()
  local path = vim.api.nvim_buf_get_name(0)
  if path ~= "" then
    local dir = vim.fn.fnamemodify(path, ":h")
    if vim.fn.isdirectory(dir) == 1 then
      return dir
    end
  end
  return vim.fn.getcwd()
end

return {
  "folke/snacks.nvim",
  keys = {
    -- Disable <C-f> for file search to allow terminal passthrough
    { "<C-f>", false, mode = { "n", "i", "v" } },
    { "<leader>ftq", function() Snacks.terminal.toggle(nil, { count = 1, cwd = vim.fn.getcwd(), win = { position = "bottom", height = 0.3, stack = true } }) end, desc = "Terminal 1" },
    { "<leader>ftw", function() Snacks.terminal.toggle(nil, { count = 2, cwd = vim.fn.getcwd(), win = { position = "bottom", height = 0.3, stack = true } }) end, desc = "Terminal 2" },
    { "<leader>fte", function() Snacks.terminal.toggle(nil, { count = 3, cwd = vim.fn.getcwd(), win = { position = "bottom", height = 0.3, stack = true } }) end, desc = "Terminal 3" },
    { "<leader>fta", function() Snacks.terminal.toggle(nil, { count = 4, cwd = vim.fn.getcwd(), win = { position = "bottom", height = 0.3, stack = true } }) end, desc = "Terminal 4" },
    { "<leader>fts", function() Snacks.terminal.toggle(nil, { count = 5, cwd = vim.fn.getcwd(), win = { position = "bottom", height = 0.3, stack = true } }) end, desc = "Terminal 5" },
    { "<leader>ftd", function() Snacks.terminal.toggle(nil, { count = 6, cwd = vim.fn.getcwd(), win = { position = "bottom", height = 0.3, stack = true } }) end, desc = "Terminal 6" },
    { "<leader>fTq", function() Snacks.terminal.toggle(nil, { count = 1, cwd = buf_dir(), win = { position = "bottom", height = 0.3, stack = true } }) end, desc = "Terminal 1 (buf dir)" },
    { "<leader>fTw", function() Snacks.terminal.toggle(nil, { count = 2, cwd = buf_dir(), win = { position = "bottom", height = 0.3, stack = true } }) end, desc = "Terminal 2 (buf dir)" },
    { "<leader>fTe", function() Snacks.terminal.toggle(nil, { count = 3, cwd = buf_dir(), win = { position = "bottom", height = 0.3, stack = true } }) end, desc = "Terminal 3 (buf dir)" },
    { "<leader>fTa", function() Snacks.terminal.toggle(nil, { count = 4, cwd = buf_dir(), win = { position = "bottom", height = 0.3, stack = true } }) end, desc = "Terminal 4 (buf dir)" },
    { "<leader>fTs", function() Snacks.terminal.toggle(nil, { count = 5, cwd = buf_dir(), win = { position = "bottom", height = 0.3, stack = true } }) end, desc = "Terminal 5 (buf dir)" },
    { "<leader>fTd", function() Snacks.terminal.toggle(nil, { count = 6, cwd = buf_dir(), win = { position = "bottom", height = 0.3, stack = true } }) end, desc = "Terminal 6 (buf dir)" },
    { "<leader>ftt", function()
      local terms = Snacks.terminal.list()
      local shown = vim.tbl_filter(function(t) return t:win_valid() end, terms)
      if #shown > 0 then
        for _, t in ipairs(shown) do t:hide() end
      elseif #terms > 0 then
        for _, t in ipairs(terms) do t:show() end
      else
        Snacks.terminal.toggle(nil, { count = 1, cwd = vim.fn.getcwd(), win = { position = "bottom", height = 0.3, stack = true } })
      end
    end, desc = "Toggle All Terminals" },
    { "<leader>fT", function()
      local terms = Snacks.terminal.list()
      local shown = vim.tbl_filter(function(t) return t:win_valid() end, terms)
      if #shown > 0 then
        for _, t in ipairs(shown) do t:hide() end
      elseif #terms > 0 then
        for _, t in ipairs(terms) do t:show() end
      else
        Snacks.terminal.toggle(nil, { count = 1, cwd = buf_dir(), win = { position = "bottom", height = 0.3, stack = true } })
      end
    end, desc = "Toggle All Terminals" },
  },
  opts = {
    scroll = {
      enabled = true, -- Disable scrolling animations
    },
    image = {
      enabled = true,
    },
    picker = {
      sources = {
        projects = {
          dev = { "~/dev/work", "~/Work/" },
          projects = {
            "~/.local/share/chezmoi",
            "~/.config/nvim",
            "~/.config/hypr",
          },
        },
        marks = {
          actions = {
            delete_mark = function(picker, item)
              if item then
                vim.cmd("delmarks " .. item.label)
                picker:find()
              end
            end,
          },
          win = {
            input = {
              keys = {
                ["<C-d>"] = { "delete_mark", mode = { "i", "n" } },
              },
            },
          },
        },
      },
      win = {
        input = {
          keys = {
            ["<PageDown>"] = { "list_scroll_down", mode = { "i", "n" } },
            ["<PageUp>"] = { "list_scroll_up", mode = { "i", "n" } },
            ["<A-;>"] = { "cycle_win", mode = { "i", "n" } },
            ["<A-j>"] = { "cycle_win", mode = { "i", "n" } },
            ["<A-w>"] = "none",
          },
        },
        list = {
          keys = {
            ["<A-;>"] = "cycle_win",
            ["<A-j>"] = "cycle_win",
            ["<A-w>"] = "none",
          },
        },
        preview = {
          keys = {
            ["<A-;>"] = "cycle_win",
            ["<A-j>"] = "cycle_win",
            ["<A-w>"] = "none",
          },
        },
      },
    },
  },
}
