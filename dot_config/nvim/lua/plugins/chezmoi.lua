-- Chezmoi helpers shared by the auto-add autocmd and the keymaps.
-- `chezmoi source-path` exits non-zero and prints nothing for unmanaged files.
local function chezmoi_source_path(file)
  local out = vim.fn.system({ "chezmoi", "source-path", file })
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return vim.fn.trim(out)
end

-- Encrypted entries are stored as `encrypted_*.age`. A plain `chezmoi add`
-- on them prompts to remove the encrypted attribute (and fails without a TTY),
-- so such files must be added with `--encrypt`.
local function chezmoi_is_encrypted(source)
  return source ~= nil and source ~= "" and (vim.endswith(source, ".age") or source:find("encrypted_", 1, true) ~= nil)
end

---Add a file to the chezmoi source state.
---@param file string
---@param source string|nil Pre-fetched `chezmoi source-path` output (optional)
---@param encrypt boolean|nil Force encryption; nil auto-detects from the source
local function chezmoi_add(file, source, encrypt)
  if source == nil then
    source = chezmoi_source_path(file)
  end
  if encrypt == nil then
    encrypt = chezmoi_is_encrypted(source)
  end

  local cmd = { "chezmoi", "add" }
  if encrypt then
    table.insert(cmd, "--encrypt")
  end
  table.insert(cmd, file)

  local result = vim.fn.system(cmd)
  local name = encrypt and "chezmoi add --encrypt" or "chezmoi add"
  if vim.v.shell_error ~= 0 then
    vim.notify(name .. " failed: " .. result, vim.log.levels.ERROR)
  else
    vim.notify(name .. ": " .. file)
  end
end

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
            if file == "" then
              return
            end
            local file_source
            vim.fn.jobstart({ chezmoi_bin, "source-path", file }, {
              stdout_buffered = true,
              on_stdout = function(_, data)
                file_source = vim.fn.trim(table.concat(data, "\n"))
              end,
              on_exit = function(_, code)
                if code == 0 then
                  -- jobstart callbacks are fast events; vim.fn.system needs the main loop
                  vim.schedule(function()
                    chezmoi_add(file, file_source)
                  end)
                end
              end,
            })
          end,
        })
      end
    end,
    keys = {
      { "<leader>Ca", desc = "Chezmoi add current file" },
      { "<leader>Ce", desc = "Chezmoi add current file (encrypted)" },
      { "<leader>Cj", desc = "Chezmoi jump source/target" },
      { "<leader>Cw", desc = "Chezmoi edit source file (watch)" },
      { "<leader>Cp", desc = "Chezmoi apply current file" },
      { "<leader>CA", desc = "Chezmoi apply all" },
      { "<leader>Cf", desc = "Find chezmoi managed files" },
    },
    config = function()
      require("chezmoi").setup({})

      local commands = require("chezmoi.commands")
      local map = vim.keymap.set

      map("n", "<leader>Ca", function()
        local file = vim.fn.expand("%:p")
        if file == "" then
          return
        end
        -- auto-detects encryption, so re-adding an encrypted file keeps it encrypted
        chezmoi_add(file)
      end, { desc = "Chezmoi add current file" })

      map("n", "<leader>Ce", function()
        local file = vim.fn.expand("%:p")
        if file == "" then
          return
        end
        chezmoi_add(file, nil, true)
      end, { desc = "Chezmoi add current file (encrypted)" })

      local function chezmoi_source_dir()
        return vim.fn.trim(vim.fn.system("chezmoi source-path"))
      end

      local function is_chezmoi_source(file)
        return vim.startswith(file, chezmoi_source_dir() .. "/")
      end

      map("n", "<leader>Cj", function()
        local file = vim.fn.expand("%:p")
        if file == "" then
          return
        end

        if is_chezmoi_source(file) then
          -- Editing a chezmoi source file: jump to the applied target file
          local target = vim.fn.trim(vim.fn.system("chezmoi target-path " .. vim.fn.shellescape(file)))
          if vim.v.shell_error ~= 0 or target == "" then
            vim.notify("No chezmoi target for " .. file, vim.log.levels.WARN)
            return
          end
          if vim.fn.filereadable(target) == 0 then
            vim.notify("Target not applied yet: " .. target, vim.log.levels.WARN)
            return
          end
          vim.cmd.edit(vim.fn.fnameescape(target))
        else
          -- Editing a target file: jump to the chezmoi source file
          commands.edit({ targets = { file }, args = {} })
        end
      end, { desc = "Chezmoi jump source/target" })

      map("n", "<leader>Cw", function()
        local file = vim.fn.expand("%:p")
        if is_chezmoi_source(file) then
          vim.notify("Already editing chezmoi source file", vim.log.levels.INFO)
          return
        end
        commands.edit({ targets = { file }, args = { "--watch" } })
      end, { desc = "Chezmoi edit source file (watch)" })

      -- Framed float with a blank winbar/statuscolumn as top/left padding.
      local function apply_term_opts(title)
        return {
          auto_close = true,
          win = {
            border = "rounded",
            title = title,
            title_pos = "center",
            wo = { winbar = " ", statuscolumn = " " },
          },
        }
      end

      map("n", "<leader>Cp", function()
        Snacks.terminal({ "chezmoi", "apply", vim.fn.expand("%:p") }, apply_term_opts(" chezmoi apply (file) "))
      end, { desc = "Chezmoi apply current file" })

      map("n", "<leader>CA", function()
        Snacks.terminal({ "chezmoi", "apply" }, apply_term_opts(" chezmoi apply "))
      end, { desc = "Chezmoi apply all" })

      map("n", "<leader>Cf", function()
        require("chezmoi.pick").snacks()
      end, { desc = "Find chezmoi managed files" })
    end,
  },
}
