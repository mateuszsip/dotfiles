-- App-specific window rules, one module per application.
-- Migrated from base/apps.conf; that file stays authoritative until phase 7.
--
-- Order matters: these run before the default-opacity rule in base/windows.lua,
-- and later rules can retag what earlier ones added (`tag -x`).
local modules = {
  "bitwarden",
  "browser",
  "hyprshot",
  "jetbrains",
  "localsend",
  "pip",
  "qemu",
  "retroarch",
  "steam",
  "geforce",
  "moonlight",
  "system",
  "telegram",
  "typora",
  "terminals",
  "webcam-overlay",
}

for _, name in ipairs(modules) do
  require("base.apps." .. name)
end
