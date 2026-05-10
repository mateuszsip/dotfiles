return {
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
            -- Adjust the container path to match your docker-compose volume mount
            -- e.g. if your volumes section has: ./:/app
            ["/app"] = "${workspaceFolder}",
          },
        },
      }
    end,
  },
}
