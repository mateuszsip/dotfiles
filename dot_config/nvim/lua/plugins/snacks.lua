return {
  "folke/snacks.nvim",
  keys = {
    -- Disable <C-f> for file search to allow terminal passthrough
    { "<C-f>", false, mode = { "n", "i", "v" } },
  },
  opts = {
    scroll = {
      enabled = false, -- Disable scrolling animations
    },
    picker = {
      sources = {
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
