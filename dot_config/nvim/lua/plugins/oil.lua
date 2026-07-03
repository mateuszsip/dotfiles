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
      desc = "Explorer Oil (file dir)",
    },
    {
      "<leader>fEc",
      function()
        require("oil").open_float(vim.uv.cwd(), { preview = { vertical = true } })
      end,
      desc = "Explorer Oil (cwd)",
    },
    {
      "<leader>fEr",
      function()
        local root = LazyVim.root()
        vim.cmd("tcd " .. vim.fn.fnameescape(root))
        require("oil").open_float(root, { preview = { vertical = true } })
      end,
      desc = "Explorer Oil (Root Dir)",
    },
    { "<leader>e", "<leader>fe", desc = "Explorer Oil (file dir)", remap = true },
    { "<leader>E", "<leader>fEc", desc = "Explorer Oil (cwd)", remap = true },
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
          local root = require("utils.path").git_toplevel(dir)
          if not root then
            return Snacks.notify.warn("Not inside a git repo")
          end
          require("utils.path").copy_relative(path, root, { dir = entry.type == "directory" })
        end,
        desc = "Copy relative path (root)",
      },
    },
  },
  config = function(_, opts)
    require("oil").setup(opts)

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
