return {
  "stevearc/oil.nvim",
  lazy = false,
  cmd = { "Oil" },
  keys = {
    {
      "<leader>fe",
      function()
        require("oil").open_float(nil, { preview = { vertical = true } })
      end,
      desc = "Explorer Oil (cwd)",
    },
    {
      "<leader>fE",
      function()
        local root = LazyVim.root()
        vim.cmd("tcd " .. vim.fn.fnameescape(root))
        require("oil").open_float(nil, { preview = { vertical = true } })
      end,
      desc = "Explorer Oil (Root Dir)",
    },
    { "<leader>e", "<leader>fe", desc = "Explorer Oil (cwd)", remap = true },
    { "<leader>E", "<leader>fE", desc = "Explorer Oil (Root Dir)", remap = true },
  },
  opts = {
    watch_for_changes = true,
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

      -- ~ = open oil at the directory of the most recent non-oil file buffer
      ["~"] = {
        callback = function()
          local dir
          local bufs = vim.fn.getbufinfo({ buflisted = 1 })
          table.sort(bufs, function(a, b)
            return a.lastused > b.lastused
          end)
          for _, info in ipairs(bufs) do
            local name = info.name
            if
              name ~= ""
              and not name:match("^oil://")
              and vim.fn.isdirectory(name) == 0
            then
              dir = vim.fn.fnamemodify(name, ":h")
              break
            end
          end
          require("oil").open_float(dir or vim.uv.cwd(), { preview = { vertical = true } })
        end,
        desc = "Open dir of last edited buffer",
      },

      -- Snacks pickers scoped to cursor entry's dir
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
    },
  },
  config = function(_, opts)
    require("oil").setup(opts)
    -- Fix: oil doesn't set title_pos on the preview window, causing first
    -- letters to be clipped with rounded borders. Patch open_preview to force
    -- title_pos = "left" (oil opens preview with noautocmd, so autocmds can't catch it).
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
  end,
}
