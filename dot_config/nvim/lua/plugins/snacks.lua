return {
  "folke/snacks.nvim",
  keys = {
    -- Disable <C-f> for file search to allow terminal passthrough
    { "<C-f>", false, mode = { "n", "i", "v" } },
    { "<leader>ft1", function() Snacks.terminal.toggle(nil, { id = 1, win = { position = "bottom", height = 0.3 } }) end, desc = "Terminal 1" },
    { "<leader>ft2", function() Snacks.terminal.toggle(nil, { id = 2, win = { position = "bottom", height = 0.3 } }) end, desc = "Terminal 2" },
    { "<leader>ft3", function() Snacks.terminal.toggle(nil, { id = 3, win = { position = "bottom", height = 0.3 } }) end, desc = "Terminal 3" },
    { "<leader>ft4", function() Snacks.terminal.toggle(nil, { id = 4, win = { position = "bottom", height = 0.3 } }) end, desc = "Terminal 4" },
    { "<leader>ftt", function()
      local terms = Snacks.terminal.list()
      local shown = vim.tbl_filter(function(t) return t:win_valid() end, terms)
      if #shown > 0 then
        for _, t in ipairs(shown) do t:hide() end
      elseif #terms > 0 then
        for _, t in ipairs(terms) do t:show() end
      else
        Snacks.terminal.toggle(nil, { id = 1, win = { position = "bottom", height = 0.3 } })
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
