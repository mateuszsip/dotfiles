return {
  {
    "xvzc/chezmoi.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "BufWritePost",
    init = function()
      local chezmoi_bin = vim.fn.exepath("chezmoi")
      if chezmoi_bin ~= "" then
        vim.api.nvim_create_autocmd("BufWritePost", {
          desc = "Auto chezmoi add on save for managed files",
          callback = function()
            local file = vim.fn.expand("%:p")
            vim.fn.jobstart({ chezmoi_bin, "source-path", file }, {
              on_exit = function(_, code)
                if code == 0 then
                  vim.fn.jobstart({ chezmoi_bin, "add", file })
                end
              end,
            })
          end,
        })
      end
    end,
    keys = {
      { "<leader>Ca", desc = "Chezmoi add current file" },
      { "<leader>Ce", desc = "Chezmoi edit source file" },
      { "<leader>Cw", desc = "Chezmoi edit source file (watch)" },
      { "<leader>Cp", desc = "Chezmoi apply current file" },
      { "<leader>Cf", desc = "Find chezmoi managed files" },
    },
    config = function()
      require("chezmoi").setup({})

      local commands = require("chezmoi.commands")
      local map = vim.keymap.set

      map("n", "<leader>Ca", function()
        local file = vim.fn.expand("%:p")
        local result = vim.fn.system("chezmoi add " .. vim.fn.shellescape(file))
        if vim.v.shell_error ~= 0 then
          vim.notify("chezmoi add failed: " .. result, vim.log.levels.ERROR)
        else
          vim.notify("chezmoi add: " .. file)
        end
      end, { desc = "Chezmoi add current file" })

      map("n", "<leader>Ce", function()
        commands.edit({ targets = { vim.fn.expand("%:p") }, args = {} })
      end, { desc = "Chezmoi edit source file" })

      map("n", "<leader>Cw", function()
        commands.edit({ targets = { vim.fn.expand("%:p") }, args = { "--watch" } })
      end, { desc = "Chezmoi edit source file (watch)" })

      map("n", "<leader>Cp", function()
        Snacks.terminal({ "chezmoi", "apply", vim.fn.expand("%:p") }, { auto_close = true })
      end, { desc = "Chezmoi apply current file" })

      map("n", "<leader>Cf", function()
        require("chezmoi.pick").snacks()
      end, { desc = "Find chezmoi managed files" })
    end,
  },
  {
    "alker0/chezmoi.vim",
    lazy = false,
    init = function()
      vim.g["chezmoi#use_tmp_buffer"] = 1
    end,
  },
}
