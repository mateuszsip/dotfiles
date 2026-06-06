return {
  { "rcarriga/nvim-dap-ui", enabled = false },

  {
    "mfussenegger/nvim-dap",
    opts = function()
      local dap = require("dap")

      -- Guard against nil command in malformed DAP responses (e.g. some Xdebug versions)
      local safe_mt = {
        __index = function(tbl, key)
          if key == nil then return nil end
          rawset(tbl, key, {})
          return rawget(tbl, key)
        end,
      }
      setmetatable(dap.listeners.before, safe_mt)
      setmetatable(dap.listeners.after, safe_mt)

      dap.configurations.php = {
        {
          type = "php",
          request = "launch",
          name = "Listen for Xdebug",
          port = 9003,
        },
        {
          type = "php",
          request = "launch",
          name = "Listen for Xdebug (Docker)",
          port = 9003,
          pathMappings = {
            ["/app"] = "${workspaceFolder}",
          },
        },
      }
    end,
  },

  {
    "igorlfs/nvim-dap-view",
    dependencies = { "mfussenegger/nvim-dap" },
    keys = {
      { "<leader>du", function() require("dap-view").toggle() end, desc = "Dap View" },
    },
    opts = {},
    config = function(_, opts)
      local dap = require("dap")
      local dapview = require("dap-view")
      dapview.setup(opts)
      dap.listeners.after.event_initialized["dap-view"] = function()
        dapview.open()
      end
      dap.listeners.before.event_terminated["dap-view"] = function()
        dapview.close()
      end
      dap.listeners.before.event_exited["dap-view"] = function()
        dapview.close()
      end
    end,
  },
}
