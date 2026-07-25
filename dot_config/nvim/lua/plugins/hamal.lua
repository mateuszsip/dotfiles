return {
  "ergodice/hamal.nvim",

  keys = function(_, keys)
    local hamal = require("hamal")
    return vim.list_extend(keys, {
      {
        "<leader>;",
        function()
          hamal.split()
        end,
        desc = "Hamal: line navigation",
        mode = { "n", "o" },
      },
      {
        "<leader>;",
        function()
          hamal.split()
        end,
        desc = "Hamal: line navigation",
        mode = { "v" },
      },
    })
  end,

  config = function()
    local hamal = require("hamal")
    hamal.setup({
      keymaps = {
        ["<esc>"] = function()
          hamal.quit()
        end,

        ["l"] = function()
          hamal.focus(1)
        end,
        ["j"] = function()
          hamal.focus(2)
        end,
        ["k"] = function()
          hamal.focus(3)
        end,

        ["s"] = function()
          hamal.select()
        end,

        ["L"] = function()
          hamal.top()
          hamal.quit()
        end,
        ["J"] = function()
          hamal.middle()
          hamal.quit()
        end,
        ["K"] = function()
          hamal.bottom()
          hamal.quit()
        end,

        ["-"] = function()
          hamal.pan_focus()
        end,
      },
    })
  end,
}
