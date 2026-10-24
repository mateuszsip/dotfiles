-- Environment variables.
-- Must load before the display server initialises, so this is the first require
-- in hyprland.lua.
--
-- Migrated from base/envs.conf; that file stays authoritative until phase 7.

-- Gum colours, generated from .chezmoidata/palette.toml
require("theme.gum-env")

-- Cursor size
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Force all apps to use Wayland
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_STYLE_OVERRIDE", "kvantum")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("OZONE_PLATFORM", "wayland")
hl.env("XDG_SESSION_TYPE", "wayland")

-- Allow better support for screen sharing (Google Meet, Discord, etc)
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

hl.config({
  xwayland = { force_zero_scaling = true },
})

-- Use XCompose file. Env values are not shell-expanded, so build the path here
-- instead of relying on `~`.
hl.env("XCOMPOSEFILE", (os.getenv("HOME") or "") .. "/.XCompose")

-- Don't show update news on first launch
hl.config({
  ecosystem = { no_update_news = true },
})
