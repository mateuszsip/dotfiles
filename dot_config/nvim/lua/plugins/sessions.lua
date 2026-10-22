-- Live nvim sessions: detach this UI, or jump between running servers.
--
-- nvim 0.12 can drop its UI and keep the editor alive (`:detach`), and move a
-- UI to another server (`:connect`). Both are only useful if the sockets are
-- tracked, which ~/.local/bin/nv does on the shell side and
-- lua/utils/live_sessions.lua reads here.
--
--   <leader>qd  detach — the editor keeps running, `nv` reattaches
--   <leader>qS  pick a running session and connect this UI to it
--
-- LazyVim owns <leader>q{d,s,S,l}, so persistence.nvim's "Don't Save Current
-- Session" moves to <leader>qD to free the short key for detaching.
local detach = function()
  if vim.fn.exists(":detach") ~= 2 then
    return vim.notify(":detach needs nvim 0.12", vim.log.levels.WARN)
  end
  vim.cmd("detach")
end

return {
  {
    "folke/persistence.nvim",
    keys = {
      { "<leader>qd", detach, desc = "Detach (editor keeps running)" },
      {
        "<leader>qD",
        function()
          require("persistence").stop()
        end,
        desc = "Don't Save Current Session",
      },
    },
  },
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>qS",
        function()
          require("utils.live_sessions").pick()
        end,
        desc = "Live nvim sessions",
      },
    },
    init = function()
      vim.api.nvim_create_user_command("NvSessions", function()
        require("utils.live_sessions").pick()
      end, { desc = "Pick a running nvim server and connect this UI to it" })
    end,
  },
}
