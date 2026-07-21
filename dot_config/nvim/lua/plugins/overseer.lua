return {
  "stevearc/overseer.nvim",
  cmd = {
    "OverseerOpen",
    "OverseerClose",
    "OverseerToggle",
    "OverseerRun",
    "OverseerShell",
    "OverseerTaskAction",
  },
  keys = {
    { "<leader>T", "", desc = "+tasks" },
    {
      "<leader>TT",
      function()
        require("overseer").toggle()
      end,
      desc = "Toggle Task List",
    },
    {
      "<leader>Tr",
      function()
        require("overseer").run_template()
      end,
      desc = "Run Task",
    },
    {
      "<leader>Ta",
      function()
        require("overseer").run_template({ auto_jump = true })
      end,
      desc = "Run Task (auto-jump)",
    },
    {
      "<leader>Tc",
      "<cmd>OverseerShell<CR>",
      desc = "Run Shell Command",
    },
    {
      "<leader>TA",
      "<cmd>OverseerTaskAction<CR>",
      desc = "Task Action",
    },
    {
      "<leader>Ti",
      "<cmd>checkhealth overseer<CR>",
      desc = "Info (checkhealth)",
    },
    {
      "<leader>Tq",
      function()
        local overseer = require("overseer")
        local tasks = overseer.list_tasks({ unique = true, recent_first = true })
        if #tasks == 0 then
          vim.notify("No tasks running", vim.log.levels.WARN)
          return
        end
        tasks[1]:stop()
      end,
      desc = "Stop Last Task",
    },
  },
  opts = {
    -- Built-in `make` template parses `make -rRpq` (internal database),
    -- which doesn't expose targets for our Makefiles. We register a custom
    -- provider below that uses `make list` instead.
    disable_template_modules = { "overseer.template.make" },
    task_list = {
      keymaps = {
        ["<C-k>"] = false,
        ["<C-j>"] = false,
        ["K"] = "keymap.scroll_output_up",
        ["L"] = "keymap.scroll_output_down",
      },
    },
  },
  config = function(_, opts)
    local overseer = require("overseer")
    overseer.setup(opts)

    overseer.register_template({
      name = "make list",
      cache_key = function(o)
        return vim.fs.find("Makefile", { upward = true, type = "file", path = o.dir })[1]
      end,
      generator = function(o, cb)
        if vim.fn.executable("make") == 0 then
          return cb({})
        end
        local makefile = vim.fs.find("Makefile", { upward = true, type = "file", path = o.dir })[1]
        if not makefile then
          return cb({})
        end
        local cwd = vim.fs.dirname(makefile)

        overseer.builtin.system(
          { "make", "list" },
          { cwd = cwd, text = true },
          vim.schedule_wrap(function(out)
            local ret = {}
            if out.code == 0 and out.stdout then
              for target in vim.gsplit(out.stdout, "\n") do
                target = target:match("^%s*(%S.*)%s*$") or ""
                if target ~= "" and not target:match("^#") then
                  local t = target
                  table.insert(ret, {
                    name = string.format("make %s", t),
                    builder = function()
                      return { cmd = { "make", t }, cwd = cwd }
                    end,
                  })
                end
              end
            end
            cb(ret)
          end)
        )
      end,
    })
  end,
}