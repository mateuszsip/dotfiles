return {
  {
    "mfussenegger/nvim-dap",
    opts = function()
      local dap = require("dap")

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
            -- Adjust the container path to match your docker-compose volume mount
            -- e.g. if your volumes section has: ./:/app
            ["/app"] = "${workspaceFolder}",
          },
        },
      }
    end,
  },
}
