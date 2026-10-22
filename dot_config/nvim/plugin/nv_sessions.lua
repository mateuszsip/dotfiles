-- `nv` marks the servers it starts with NV_SESSION_KEY, and only those get
-- snapshot save/restore (lua/utils/nv_sessions.lua). A plain `nvim` is left
-- exactly as before.
if vim.env.NV_SESSION_KEY and vim.env.NV_SESSION_KEY ~= "" then
  require("utils.nv_sessions").setup()
end
