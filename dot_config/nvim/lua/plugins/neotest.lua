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
            -- Get the current buffer's file path
            local current_file = vim.api.nvim_buf_get_name(0)

            if string.find(current_file, "creditcard") then
              -- Extract service name from path like /path/to/creditcard/services/myservice/...
              local service = current_file:match("/services/([^/]+)")

              if not service then
                vim.notify("Could not detect service from path: " .. current_file, vim.log.levels.ERROR)
                error("Service detection failed - path must contain /services/[service-name]/")
              end

              -- Extract service directory path (e.g., /path/to/creditcard/services/billing)
              local service_dir = current_file:match("(.*/services/" .. service .. ")")
              if not service_dir then
                vim.notify("Could not find service directory", vim.log.levels.ERROR)
                error("Failed to detect service directory")
              end

              vim.notify("Service: " .. service, vim.log.levels.INFO)

              return {
                "docker",
                "compose",
                "-f",
                service_dir .. "/build/local/docker-compose.full.yaml",
                "exec",
                "--user",
                "app",
                service .. "-php-fpm",
                "php",
                "vendor/bin/phpunit",
              }
            else
              return "vendor/bin/phpunit"
            end
          end,
          filter_dirs = { "vendor" },
        }),
      },
    })
  end,
}
