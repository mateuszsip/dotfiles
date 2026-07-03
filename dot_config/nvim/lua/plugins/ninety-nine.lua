return {
  "ThePrimeagen/99",
  dependencies = { { "saghen/blink.compat", version = "2.*" } },
  config = function()
    local _99 = require("99")
    local cwd = vim.uv.cwd()
    local basename = vim.fs.basename(cwd)

    _99.setup({
      -- provider = _99.Providers.ClaudeCodeProvider, -- default: OpenCodeProvider
      model = "opencode/glm-5.2",

      logger = {
        level = _99.DEBUG,
        path = "/tmp/" .. basename .. ".99.debug",
        print_on_error = true,
      },

      -- Must be inside CWD or opencode/claude will have permission issues
      -- https://opencode.ai/docs/permissions/#external-directories
      tmp_dir = "./tmp",

      completion = {
        source = "blink", -- you use blink.cmp
        custom_rules = {
          -- "scratch/custom_rules/",
        },
        files = {
          -- enabled = true,
          -- max_file_size = 102400,
          -- max_files = 5000,
        },
      },

      -- Auto-load context files found walking up from the current buffer
      -- to project root. You use CLAUDE.md; AGENT.md is 99's convention.
      md_files = {
        "AGENT.md",
        "CLAUDE.md",
      },
    })

    -- Visual: send selection + prompt, replace selection with result
    -- (v-mode only so stale visual selections aren't reused)
    vim.keymap.set("v", "<leader>9v", function()
      _99.visual()
    end, { desc = "99 Visual" })

    -- Search: agentic search across project, results in quickfix
    vim.keymap.set("n", "<leader>9s", function()
      _99.search()
    end, { desc = "99 Search" })

    -- Stop all in-flight requests
    vim.keymap.set("n", "<leader>9x", function()
      _99.stop_all_requests()
    end, { desc = "99 Stop" })

    -- Open last interaction (quickfix for search/vibe)
    vim.keymap.set("n", "<leader>9o", function()
      _99.open()
    end, { desc = "99 Open" })

    -- View logs from the last run
    vim.keymap.set("n", "<leader>9l", function()
      _99.view_logs()
    end, { desc = "99 Logs" })
  end,
}
