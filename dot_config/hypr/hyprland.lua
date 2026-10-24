-- Hyprland entry point (Lua).
-- Deploys to ~/.config/hypr/hyprland.lua.
--
-- Hyprland enters Lua mode purely on this file existing; there is no fallback
-- to hyprland.conf. A parse error anywhere in the require graph drops the
-- session to Emergency.hpp (SUPER+Q terminal, SUPER+M exit), so run
-- `hyprland -c ~/.config/hypr/hyprland.lua --verify-config` after edits.
--
-- Order matters:
--   * env first (must be set before the display server initialises)
--   * rules before the palette overrides, because rule evaluation is top-down

require("base.envs")

-- Base config (vendored from Omarchy 3.8.5, now owned here)
require("base.looknfeel")
require("base.input")
require("base.windows")

-- Theme colours generated from .chezmoidata/palette.toml
require("theme.hyprland")

-- Personal setup: overrides anything set above
require("monitors")
require("input")
require("base.bindings.media")
require("base.bindings.clipboard")
require("base.bindings.tiling-v2")
require("base.bindings.utilities")
require("bindings")
require("looknfeel")

-- Autostart: both files register hyprland.start handlers, base runs first
require("base.autostart")
require("autostart")

-- App workspace assignments
hl.window_rule({ match = { class = "zen" }, workspace = "1 silent" })
hl.window_rule({ match = { class = "(BambuStudio|bambu-studio)" }, workspace = "5 silent" })
hl.window_rule({ match = { class = "steam" }, workspace = "7 silent" })
hl.window_rule({ match = { class = "chrome-web.whatsapp.com__-Profile_1" }, workspace = "4 silent" })
hl.window_rule({ match = { class = "feishin" }, workspace = "9 silent" })
hl.window_rule({ match = { class = "Bitwarden" }, workspace = "10 silent" })
hl.window_rule({ match = { class = "Bitwarden" }, float = false })

-- Runtime toggles, written by sys-window / sys-monitor / sys-touchpad.
--
-- Each script drops a <name>.lua snippet into the state dir and reloads. Lua
-- has no directory glob, so the list is explicit — adding a toggle means adding
-- it here as well. Everything is pcall'd: a broken toggle must not take down
-- the rest of the config.
local toggle_dir = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/hypr/toggles/"

for _, name in ipairs({
  "window-no-gaps",
  "single-window-aspect-ratio",
  "internal-monitor-disable",
  "internal-monitor-mirror",
  "touchpad-disabled",
}) do
  local handle = io.open(toggle_dir .. name .. ".lua", "r")
  if handle then
    handle:close()
    local ok, err = pcall(dofile, toggle_dir .. name .. ".lua")
    if not ok then
      print("hyprland.lua: toggle '" .. name .. "' failed: " .. tostring(err))
    end
  end
end
