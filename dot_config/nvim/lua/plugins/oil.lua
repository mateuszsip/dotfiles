return {
  "stevearc/oil.nvim",
  lazy = false,
  cmd = { "Oil" },
  keys = {
    {
      "<leader>fee",
      function()
        require("oil").open_float(nil, { preview = { vertical = true } })
      end,
      desc = "Explorer Oil (file dir)",
    },
    {
      "<leader>fec",
      function()
        require("oil").open_float(vim.uv.cwd(), { preview = { vertical = true } })
      end,
      desc = "Explorer Oil (cwd)",
    },
    {
      "<leader>fer",
      function()
        local root = LazyVim.root()
        vim.cmd("tcd " .. vim.fn.fnameescape(root))
        require("oil").open_float(root, { preview = { vertical = true } })
      end,
      desc = "Explorer Oil (Root Dir)",
    },
    { "<leader>e", "<leader>fee", desc = "Explorer Oil (file dir)", remap = true },
    { "<leader>E", "<leader>fec", desc = "Explorer Oil (cwd)", remap = true },
  },
  opts = {
    watch_for_changes = true,
    columns = { "icon", "operms", { "mtime", format = "%d-%m-%y" } },
    view_options = {
      show_hidden = true,
    },
    float = {
      padding = 2,
      max_width = 0.8,
      max_height = 0.8,
      border = "rounded",
      win_options = { winblend = 0 },
    },
    confirmation = { border = "rounded" },
    progress = { border = "rounded", minimized_border = "none" },
    ssh = { border = "rounded" },
    keymaps_help = { border = "rounded" },
    keymaps = {
      -- default `` ` `` (backtick) = actions.cd  -> change cwd to current dir

      -- q / <Esc> = close oil window (float or split)
      ["q"] = {
        callback = function()
          vim.cmd("close")
        end,
        desc = "Close oil",
      },
      ["<Esc>"] = {
        callback = function()
          vim.cmd("close")
        end,
        desc = "Close oil",
      },

      -- <Tab> = toggle focus between oil list and preview
      ["<Tab>"] = {
        callback = function()
          -- If in preview, go back to oil list
          local ok, is_p = pcall(vim.api.nvim_win_get_var, 0, "oil_preview")
          if ok and is_p then
            for _, w in ipairs(vim.api.nvim_list_wins()) do
              local ok2, is_oil = pcall(vim.api.nvim_win_get_var, w, "is_oil_win")
              if ok2 and is_oil and vim.api.nvim_win_is_valid(w) then
                vim.api.nvim_set_current_win(w)
                return
              end
            end
            return
          end
          -- Otherwise, focus preview
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            local ok2, is_p2 = pcall(vim.api.nvim_win_get_var, win, "oil_preview")
            if ok2 and is_p2 and vim.api.nvim_win_is_valid(win) then
              vim.api.nvim_set_current_win(win)
              vim.cmd("stopinsert")
              return
            end
          end
        end,
        desc = "Toggle oil list / preview",
      },
      ["<leader>sf"] = {
        callback = function()
          local oil = require("oil")
          local dir = oil.get_current_dir()
          if not dir then
            return
          end
          local entry = oil.get_cursor_entry()
          if entry and entry.type == "directory" then
            dir = dir .. "/" .. entry.name
          end
          Snacks.picker.files({ cwd = dir })
        end,
        desc = "Find files in cursor dir",
      },
      ["<leader>sg"] = {
        callback = function()
          local oil = require("oil")
          local dir = oil.get_current_dir()
          if not dir then
            return
          end
          local entry = oil.get_cursor_entry()
          if entry and entry.type == "directory" then
            dir = dir .. "/" .. entry.name
          end
          Snacks.picker.grep({ cwd = dir })
        end,
        desc = "Grep in cursor dir",
      },
      ["<leader>RF"] = {
        callback = function()
          local oil = require("oil")
          local dir = oil.get_current_dir()
          if not dir then
            return
          end
          local entry = oil.get_cursor_entry()
          if entry and entry.type == "directory" then
            dir = dir .. "/" .. entry.name
          end
          require("utils.kulala").search_requests_in_dir(dir)
        end,
        desc = "Find HTTP requests in cursor dir",
      },
      ["<leader>yr"] = {
        callback = function()
          local oil = require("oil")
          local dir = oil.get_current_dir()
          if not dir then
            return
          end
          local entry = oil.get_cursor_entry()
          if not entry then
            return
          end
          local path = dir .. "/" .. entry.name
          require("utils.path").copy_relative(path, vim.uv.cwd(), { dir = entry.type == "directory" })
        end,
        desc = "Copy relative path (cwd)",
      },
      ["<leader>yR"] = {
        callback = function()
          local oil = require("oil")
          local dir = oil.get_current_dir()
          if not dir then
            return
          end
          local entry = oil.get_cursor_entry()
          if not entry then
            return
          end
          local path = dir .. "/" .. entry.name
          require("utils.path").copy_relative(path, LazyVim.root(), { dir = entry.type == "directory" })
        end,
        desc = "Copy relative path (root)",
      },
    },
  },
  config = function(_, opts)
    -- Custom column: numeric (octal) permissions, e.g. "755" or "4755".
    -- Each digit gets its own highlight: special / user / group / other.
    local columns = require("oil.columns")
    local permissions = require("oil.adapters.files.permissions")
    local FIELD_META = require("oil.constants").FIELD_META
    columns.register("operms", {
      require_stat = true,
      render = function(entry, conf)
        local meta = entry[FIELD_META]
        local stat = meta and meta.stat
        if not stat then
          return columns.EMPTY
        end
        local s = permissions.mode_to_octal_str(stat.mode):gsub("^0(%d%d%d)$", "%1")
        local hls = {}
        for i = 1, #s do
          local d = s:sub(i, i)
          table.insert(hls, { "OilPermsDigit" .. d, i - 1, i })
        end
        return { s, hls }
      end,
      parse = function(line, conf)
        local octal, rem = line:match("^(%d%d%d%d?)%s+(.*)$")
        if not octal then
          return
        end
        local mode = tonumber(octal, 8)
        if not mode then
          return
        end
        return mode, rem
      end,
      compare = function(entry, parsed_value)
        local meta = entry[FIELD_META]
        if parsed_value and meta and meta.stat and meta.stat.mode then
          local mask = bit.lshift(1, 12) - 1
          if parsed_value ~= bit.band(meta.stat.mode, mask) then
            return true
          end
        end
        return false
      end,
      render_action = function(action)
        local _, path = require("oil.util").parse_url(action.url)
        assert(path)
        return string.format(
          "CHMOD %s %s",
          permissions.mode_to_octal_str(action.value),
          require("oil.adapters.files").to_short_os_path(path, action.entry_type)
        )
      end,
      perform_action = function(action, callback)
        local util = require("oil.util")
        local fs = require("oil.fs")
        local uv = vim.uv
        local _, path = util.parse_url(action.url)
        assert(path)
        path = fs.posix_to_os_path(path)
        uv.fs_stat(path, function(err, stat)
          if err then
            return callback(err)
          end
          assert(stat)
          local mask = bit.bnot(bit.lshift(1, 12) - 1)
          local old_mode = bit.band(stat.mode, mask)
          uv.fs_chmod(path, bit.bor(old_mode, action.value), callback)
        end)
      end,
    })

    require("oil").setup(opts)

    -- Highlight groups per digit value 0-7 for the operms column.
    local perm_hls = {
      [0] = "Comment",      -- no perms (---)
      [1] = "DiagnosticWarn", -- execute only (--x)
      [2] = "DiagnosticOk",   -- write only (-w-)
      [3] = "DiagnosticOk",   -- write+exec (-wx)
      [4] = "Special",      -- read only (r--)
      [5] = "Statement",    -- read+exec (r-x)
      [6] = "Constant",     -- read+write (rw-)
      [7] = "Error",        -- all perms (rwx)
    }
    for d = 0, 7 do
      vim.api.nvim_set_hl(0, "OilPermsDigit" .. d, { link = perm_hls[d] })
    end

    -- Fix: oil doesn't set title_pos on the preview window, causing first
    -- letters to be clipped with rounded borders.
    local oil = require("oil")
    local orig_open_preview = oil.open_preview
    oil.open_preview = function(o, cb)
      orig_open_preview(o, cb)
      vim.schedule(function()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          local ok, is_p = pcall(vim.api.nvim_win_get_var, win, "oil_preview")
          if ok and is_p then
            pcall(vim.api.nvim_win_set_config, win, { title_pos = "left" })
          end
        end
      end)
    end

    -- Set <Tab> on file preview buffers to focus back to oil list.
    -- Uses BufWinEnter + vim.schedule so it runs AFTER filetype plugins
    -- (which may set their own <Tab>).
    vim.api.nvim_create_autocmd("BufWinEnter", {
      group = vim.api.nvim_create_augroup("OilPreviewTab", { clear = true }),
      callback = function(ev)
        local win = vim.api.nvim_get_current_win()
        local ok, is_p = pcall(vim.api.nvim_win_get_var, win, "oil_preview")
        if not ok or not is_p then
          return
        end
        vim.schedule(function()
          if not vim.api.nvim_win_is_valid(win) then
            return
          end
          local ok2, still_p = pcall(vim.api.nvim_win_get_var, win, "oil_preview")
          if not ok2 or not still_p then
            return
          end
          vim.keymap.set("n", "<Tab>", function()
            for _, w in ipairs(vim.api.nvim_list_wins()) do
              local ok3, is_oil = pcall(vim.api.nvim_win_get_var, w, "is_oil_win")
              if ok3 and is_oil and vim.api.nvim_win_is_valid(w) then
                vim.api.nvim_set_current_win(w)
                return
              end
            end
          end, { buffer = ev.buf, nowait = true, desc = "Back to oil list" })
        end)
      end,
    })
  end,
}
