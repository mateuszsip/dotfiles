-- Extra autostart processes.
-- Migrated from autostart.conf

hl.on("hyprland.start", function()
  -- Second attempt at Waybar (the first is in base/autostart.lua). sys-waybar-start
  -- serialises on a lock and waits for the bar to appear, so this cannot race the
  -- first launch — which a fixed `sleep 2; pgrep` did whenever `uwsm-app` was slow
  -- to cold-start its daemon after login (two bars).
  hl.exec_cmd("sys-waybar-start")
  hl.exec_cmd("systemd-run --user --no-block bash ~/.config/waybar/ai-workspace-watcher.sh")
  hl.exec_cmd("systemd-run --user --no-block bash ~/.config/waybar/notification-watcher.sh")
  hl.exec_cmd("uwsm-app -- zen-browser")

  -- Bitwarden: tray app, also provides the SSH agent used for git signing
  hl.exec_cmd("uwsm-app -- bitwarden-desktop")

  -- `[workspace N silent]` becomes the second argument: window-rule effects
  -- applied to the window this command spawns.
  -- Rex client instead of a bare terminal on the two workspaces (launched
  -- directly, not through uwsm-app: the [workspace N silent] rule tracks the
  -- spawned process, and rexia's wrapper execs so the PID is the client).
  hl.exec_cmd("rexia", { workspace = "2 silent" })
  hl.exec_cmd("rexia", { workspace = "3 silent" })

  -- Music client: opens on ws 9 without switching to it (see the matching
  -- class rule in hyprland.lua, which keeps it there on every later launch).
  hl.exec_cmd("uwsm-app -- spotifast")

  -- Keep Ghostty font size in sync with the monitor setup (12 undocked / 14 docked)
  hl.exec_cmd("systemd-run --user --no-block --unit=ghostty-font-monitor bash ~/.config/hypr/scripts/ghostty-font-monitor.sh")
end)
