-- Per-server snapshots, so a reboot does not cost you the layout.
--
-- A process cannot outlive a reboot, so `nv` rebuilds it: every server it
-- starts gets NV_SESSION_KEY in its environment, and that server writes its
-- own `:mksession` file to $XDG_STATE_HOME/nvim/nv-sessions/<key>.vim —
-- on detach, on exit (systemd's SIGTERM at shutdown counts), and on a slow
-- timer to cover crashes. `nv` restores the snapshot when the server starts
-- again, and `nv -R` respawns every saved server after a boot.
--
-- What comes back: buffers, window layout, tab pages, folds, cwd, cursor,
-- registers/marks/history (shada), undo (undofile). What cannot: running
-- `:terminal` buffers (a session file cannot recreate them), LSP servers
-- (restarted when the buffers reopen), and anything in memory anywhere else.
-- CodeCompanion chats are the exception: their ACP session ids are saved with
-- each snapshot (lua/utils/cc_chats.lua) and reloaded on start, like <leader>aL.

local M = {}

local key = vim.env.NV_SESSION_KEY

local function state_dir()
  return (vim.env.XDG_STATE_HOME or (vim.env.HOME .. "/.local/state")) .. "/nvim/nv-sessions"
end

--- Snapshot path for the current server, or nil outside `nv`.
function M.file()
  if not key or key == "" then
    return nil
  end
  return state_dir() .. "/" .. (key:gsub("[^%w%%~%._%-]", "_")) .. ".vim"
end

local function save()
  local path = M.file()
  if not path then
    return
  end
  require("utils.cc_chats").save()
  vim.fn.mkdir(state_dir(), "p")
  -- mksession complains about odd buffers; the snapshot is still worth taking.
  pcall(vim.cmd, "silent! mksession! " .. vim.fn.fnameescape(path))
end

--- Drop the scratch buffers (dashboard, nofile panes) that would otherwise
--- take a window away from the restored layout.
local function wipe_scratch()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(buf)
    local scratch = vim.bo[buf].buftype == "nofile" or name == ""
    if scratch and name ~= "" and not vim.bo[buf].modified then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end
end

--- Source this server's snapshot, if there is one.
function M.restore()
  local path = M.file()
  if not path or vim.fn.filereadable(path) ~= 1 then
    return false
  end
  wipe_scratch()
  local ok = pcall(vim.cmd, "silent! source " .. vim.fn.fnameescape(path))
  if not ok then
    vim.notify("nv: could not restore " .. path, vim.log.levels.WARN)
  end
  return ok
end

function M.setup()
  if not key or key == "" then
    return
  end
  local group = vim.api.nvim_create_augroup("NvSession", { clear = true })

  vim.api.nvim_create_autocmd("VimLeavePre", { group = group, callback = save, desc = "nv: snapshot on exit" })
  vim.api.nvim_create_autocmd("UILeave", {
    group = group,
    callback = function()
      -- detaching the last UI: this is the normal "park it" moment
      vim.schedule(save)
    end,
    desc = "nv: snapshot on detach",
  })
  vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    callback = function()
      -- after startup, so the dashboard/plugins are in their final shape
      vim.schedule(function()
        M.restore()
        -- CodeCompanion chats: after the snapshot, which sets the cwd they
        -- are keyed by, and once a UI is attached, so the windows are laid
        -- out for the real terminal instead of the headless 80x24 grid
        local cc_chats = require("utils.cc_chats")
        if #vim.api.nvim_list_uis() > 0 then
          cc_chats.startup()
        else
          vim.api.nvim_create_autocmd("UIEnter", {
            group = group,
            once = true,
            callback = function()
              vim.schedule(cc_chats.startup)
            end,
            desc = "nv: restore CodeCompanion chats",
          })
        end
      end)
    end,
    desc = "nv: restore snapshot",
  })

  -- Crash net: no VimLeavePre on SIGKILL, so checkpoint while running.
  local timer = vim.uv.new_timer()
  timer:start(60000, 60000, vim.schedule_wrap(save))
  timer:unref()
end

return M
