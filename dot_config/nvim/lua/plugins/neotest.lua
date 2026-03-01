return {
  "nvim-neotest/neotest",
  dependencies = {
    "olimorris/neotest-phpunit",
  },
  opts = {
    adapters = {
      ["neotest-phpunit"] = {
        phpunit_cmd = function()
          local path = vim.fn.getcwd()
          if (string.find(path, "creditcard")) then
            local service = path:gsub('.*%/', '')

            return {
              "docker compose",
              "exec",
              "-f ./build/local/docker-compose.full.yaml",
              "--user app",
              service .. "-php-fpm",
              "php",
              "vendor/bin/phpunit",
            }
          else
            return "vendor/bin/phpunit"
          end
        end,
        filter_dirs = { "vendor" },
      },
    },
  },
}
