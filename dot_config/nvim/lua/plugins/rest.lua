-- rest.nvim replaces mistweaverco/kulala.nvim (repo was deleted from GitHub).
-- Same JetBrains .http spec, so existing `### NAME` files keep working.
--
-- NOTE: each spec below is wrapped in its own table. lazy.nvim parses a table
-- with 2+ array elements as a *list of specs*, silently dropping its named
-- fields -- the old `{ "rest-nvim/rest.nvim", init = ..., ft = ..., keys = ...,
-- { treesitter } }` form made rest.nvim a start plugin whose init/ft/keys were
-- never applied, so it loaded at startup and crashed on the highlights bug
-- below under flexoki.
return {
  {
    "rest-nvim/rest.nvim",
    init = function()
      -- rest.nvim's ftdetect only maps .http; keep .rest files working too
      vim.filetype.add({ extension = { rest = "http" } })

      -- rest.nvim (714d551, upstream idle since 2025-12) crashes when the
      -- plugin is sourced if the active colorscheme leaves a base group like
      -- Statement without an fg (flexoki/flexoki-light define @keyword only):
      --   lua/rest-nvim/ui/highlights.lua:23: bad argument #2 to 'get_hl_group_fg'
      -- (number expected, got nil). Shim the module via package.preload until
      -- upstream ships a fix: resolve links, fall back to the @-group,
      -- tolerate a missing fg, and re-derive on colorscheme switches.
      package.preload["rest-nvim.ui.highlights"] = function()
        local function get_hl_group_fg(names)
          for _, name in ipairs(names) do
            local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
            if ok and type(hl) == "table" and type(hl.fg) == "number" then
              return string.format("#%06X", hl.fg)
            end
          end
          return nil
        end

        local function define_highlights()
          vim.api.nvim_set_hl(0, "RestText", { fg = get_hl_group_fg({ "Comment", "@comment" }), default = true })
          vim.api.nvim_set_hl(0, "RestPaneTitleNC", {
            fg = get_hl_group_fg({ "Statement", "@keyword" }),
            default = true,
          })
          vim.api.nvim_set_hl(0, "RestPaneTitle", {
            fg = get_hl_group_fg({ "Statement", "@keyword" }),
            bold = true,
            underline = true,
            default = true,
          })
        end

        define_highlights()
        local group = vim.api.nvim_create_augroup("rest-nvim-highlights", { clear = true })
        vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = define_highlights })

        return {}
      end
    end,
    ft = { "http", "rest" },
    keys = {
      { "<leader>R", "", desc = "+Rest" },
      -- same keys as the old LazyVim util.rest extra where rest.nvim has equivalents
      { "<leader>Rs", "<cmd>Rest run<cr>", desc = "Send the request", ft = { "http", "rest" } },
      { "<leader>Rr", "<cmd>Rest last<cr>", desc = "Replay the last request", ft = { "http", "rest" } },
      { "<leader>Rc", "<cmd>Rest curl yank<cr>", desc = "Copy as cURL", ft = { "http", "rest" } },
      { "<leader>Re", "<cmd>Rest env select<cr>", desc = "Select environment", ft = { "http", "rest" } },
      { "<leader>Ro", "<cmd>Rest open<cr>", desc = "Open result pane", ft = { "http", "rest" } },
      -- in-file search (rest.nvim has no built-in search)
      {
        "<leader>Rf",
        function()
          require("utils.rest").search_requests_in_file()
        end,
        desc = "Find request in file",
        ft = { "http", "rest" },
      },
      -- directory-wide search
      {
        "<leader>RF",
        function()
          require("utils.rest").search_requests_in_dir(vim.fn.getcwd())
        end,
        desc = "Find HTTP requests in CWD",
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "http", "graphql" } },
  },
}
