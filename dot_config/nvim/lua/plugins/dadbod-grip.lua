-- Grid-editing database workspace on top of the `vim.g.dbs` list that
-- utils/dbcreds.lua maintains. Deliberately independent of vim-dadbod: it
-- reads g:dbs directly and shells out to psql/mysql/sqlite3 itself, so it can
-- be trialled next to dadbod.lua and either side can be deleted afterwards.
return {
  {
    "joryeugene/dadbod-grip.nvim",
    cmd = { "Grip", "GripConnect", "GripHome", "GripQuery", "GripTables", "GripToggle" },
    keys = {
      { "<leader>Dg", desc = "Grip: home" },
      { "<leader>Dc", desc = "Grip: connections" },
    },
    opts = {
      picker = "snacks",
      completion = true, -- blink.cmp integration (lua/dadbod-grip/completion/blink.lua)
      open_sidebar = true,
    },
    config = function(_, opts)
      local dbcreds = require("utils.dbcreds")
      require("dadbod-grip").setup(opts)

      -- grip mirrors every g:dbs entry into ~/.grip/connections.json verbatim
      -- (connections.lua, M.list), and those URLs carry live Vault lease
      -- passwords. Park that one file on tmpfs so a lease never outlives the
      -- session - a missing registry is read as empty. Consequence: connection
      -- IDs saved with queries are session-scoped too.
      local function contain_global_registry()
        local uv = vim.uv
        local dir = vim.fn.expand("~/.grip")
        local registry = dir .. "/connections.json"
        local runtime = (vim.env.XDG_RUNTIME_DIR or "/tmp") .. "/dadbod-grip"

        vim.fn.mkdir(dir, "p")
        vim.fn.mkdir(runtime, "p")
        pcall(uv.fs_chmod, dir, 448) -- 0700
        pcall(uv.fs_chmod, runtime, 448)

        local stat = uv.fs_lstat(registry)
        if stat and stat.type == "link" then
          return
        end
        if stat then
          -- A real registry from before this containment: keep it, then swap.
          uv.fs_rename(registry, registry .. ".bak")
        end
        pcall(uv.fs_symlink, runtime .. "/connections.json", registry)
      end
      contain_global_registry()

      -- Populate g:dbs before anything can open a picker, so a bare
      -- `:GripConnect` works without going through <leader>Dc first.
      dbcreds.refresh()

      -- g:dbs is read when the picker builds its list, so refresh again or a
      -- new Vault lease (or a fresh source file) would not be visible.
      vim.keymap.set("n", "<leader>Dc", function()
        dbcreds.refresh()
        vim.cmd("GripConnect")
      end, { desc = "Grip: connections" })

      vim.keymap.set("n", "<leader>Dg", "<cmd>GripHome<cr>", { desc = "Grip: home" })
    end,
  },
}
