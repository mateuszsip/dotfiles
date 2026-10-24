-- Base autostart.
-- Migrated from base/autostart.conf
--
-- `hl.exec_cmd` runs the command through `sh -c`, exactly like `exec-once` did,
-- so shell syntax and `~` still work. It is asynchronous — no `&`/`disown`.

hl.on("hyprland.start", function()
  hl.exec_cmd("uwsm-app -- hypridle")
  hl.exec_cmd("uwsm-app -- mako")
  hl.exec_cmd("! sys-toggle enabled waybar-off && uwsm-app -- waybar")
  hl.exec_cmd("uwsm-app -- fcitx5 --disable notificationitem")

  -- Wallpaper (path comes from .chezmoidata/palette.toml)
  hl.exec_cmd("uwsm-app -- sys-background")
  hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
  hl.exec_cmd("sys-monitor watch")

  -- Slow app launch fix -- set systemd vars
  hl.exec_cmd("systemctl --user import-environment $(env | cut -d'=' -f 1)")
  hl.exec_cmd("dbus-update-activation-environment --systemd --all")
end)
