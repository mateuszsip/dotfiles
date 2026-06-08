return {
  { "rcarriga/nvim-dap-ui", enabled = false },

  {
    "mfussenegger/nvim-dap",
    opts = function()
      local dap = require("dap")

      -- Guard against nil command in malformed DAP responses (e.g. some Xdebug versions)
      local safe_mt = {
        __index = function(tbl, key)
          if key == nil then
            return {}
          end
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
    "mfussenegger/nvim-dap",
    keys = {
      {
        "<leader>dc",
        function()
          require("dap").continue()
        end,
        desc = "DAP Continue",
      },
      {
        "<leader>do",
        function()
          require("dap").step_over()
        end,
        desc = "DAP Step Over",
      },
      {
        "<leader>di",
        function()
          require("dap").step_into()
        end,
        desc = "DAP Step Into",
      },
      {
        "<leader>dO",
        function()
          require("dap").step_out()
        end,
        desc = "DAP Step Out",
      },
      {
        "<leader>db",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "DAP Toggle Breakpoint",
      },
      {
        "<leader>dB",
        function()
          require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end,
        desc = "DAP Conditional Breakpoint",
      },
      {
        "<leader>dk",
        function()
          require("dap-view").hover()
        end,
        desc = "DAP Hover",
        mode = { "n", "v" },
      },
      {
        "<leader>dq",
        function()
          require("dap").terminate()
        end,
        desc = "DAP Terminate",
      },
    },
  },

  {
    "igorlfs/nvim-dap-view",
    dependencies = { "mfussenegger/nvim-dap" },
    keys = {
      {
        "<leader>du",
        function()
          require("dap-view").toggle()
        end,
        desc = "Dap View",
      },
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
