return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "olimorris/neotest-phpunit",
  },
  config = function()
    local status_ok, neotest = pcall(require, "neotest")
    if not status_ok then
      vim.notify("Failed to load neotest", vim.log.levels.ERROR)
      return
    end

    neotest.setup({
      adapters = {
        require("neotest-phpunit")({
          phpunit_cmd = function()
            local current_file = vim.api.nvim_buf_get_name(0)
            if string.find(current_file, "creditcard") then
              return vim.fn.stdpath("config") .. "/bin/phpunit-neotest-creditcard"
            end
            return "vendor/bin/phpunit"
          end,
          filter_dirs = { "vendor" },
          dap = { port = 9003, request = "launch" },
        }),
      },
    })
  end,
  keys = {
    { "<leader>t", "", desc = "+test" },
    {
      "<leader>ta",
      function()
        require("neotest").run.attach()
      end,
      desc = "Attach to Test (Neotest)",
    },
    {
      "<leader>tt",
      function()
        require("neotest").run.run(vim.fn.expand("%"))
      end,
      desc = "Run File (Neotest)",
    },
    {
      "<leader>tT",
      function()
        require("neotest").run.run(vim.uv.cwd())
      end,
      desc = "Run All Test Files (Neotest)",
    },
    {
      "<leader>tr",
      function()
        require("neotest").run.run()
      end,
      desc = "Run Nearest (Neotest)",
    },
    {
      "<leader>tD",
      function()
        require("neotest").run.run({ strategy = "dap" })
      end,
      desc = "Debug Nearest (Neotest)",
    },
    {
      "<leader>td",
      function()
        local file = vim.api.nvim_buf_get_name(0)
        local service_dir = file:match("(.*services/[^/]+)/")
        if not service_dir then
          vim.notify("Could not detect service directory from current file", vim.log.levels.ERROR)
          return
        end
        local dap = require("dap")
        -- Fire once when the adapter is initialized and ready to accept Xdebug connections
        dap.listeners.after.event_initialized["neotest_docker_debug"] = function()
          dap.listeners.after.event_initialized["neotest_docker_debug"] = nil
          vim.notify("Xdebug listener ready — running test", vim.log.levels.INFO)
          vim.schedule(function()
            require("neotest").run.run({ env = { XDEBUG_DEBUG = "1" } })
          end)
        end
        dap.run({
          type = "php",
          request = "launch",
          name = "Neotest Docker Debugger",
          port = 9003,
          pathMappings = { ["/app"] = service_dir },
        })
      end,
      desc = "Debug Nearest in Docker (Neotest)",
    },
    {
      "<leader>tl",
      function()
        require("neotest").run.run_last()
      end,
      desc = "Run Last (Neotest)",
    },
    {
      "<leader>ts",
      function()
        require("neotest").summary.toggle()
      end,
      desc = "Toggle Summary (Neotest)",
    },
    {
      "<leader>to",
      function()
        require("neotest").output.open({ enter = true, auto_close = true })
      end,
      desc = "Show Output (Neotest)",
    },
    {
      "<leader>tO",
      function()
        require("neotest").output_panel.toggle()
      end,
      desc = "Toggle Output Panel (Neotest)",
    },
    {
      "<leader>tS",
      function()
        require("neotest").run.stop()
      end,
      desc = "Stop (Neotest)",
    },
    {
      "<leader>tw",
      function()
        require("neotest").watch.toggle(vim.fn.expand("%"))
      end,
      desc = "Toggle Watch (Neotest)",
    },
  },
}
