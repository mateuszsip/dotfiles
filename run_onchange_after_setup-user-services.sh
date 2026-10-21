#!/bin/bash
# Enable the user units this repo manages (idempotent) and retire the omarchy
# ones. Runs after `chezmoi apply` whenever this file changes.

set -uo pipefail

# No user systemd manager (e.g. applying over ssh): nothing to do.
systemctl --user daemon-reload 2>/dev/null || exit 0

# Retire the omarchy session services — sys-battery-monitor.timer replaces
# omarchy-battery-monitor.timer. walker stays: elephant.service feeds it.
systemctl --user disable omarchy-battery-monitor.timer 2>/dev/null

for unit in \
  elephant.service \
  sys-battery-monitor.timer \
  sys-recover-internal-monitor.service \
  swayosd-server.service \
  syncthing.service; do
  if ! systemctl --user enable "$unit" >/dev/null 2>&1; then
    echo "setup-user-services: could not enable $unit" >&2
  fi
done

systemctl --user start sys-battery-monitor.timer 2>/dev/null
systemctl --user start sys-recover-internal-monitor.service 2>/dev/null
systemctl --user start elephant.service 2>/dev/null

# The old omarchy timer/service files are not owned by chezmoi; remove them
# once they are disabled so nothing can start them again.
rm -f "$HOME/.config/systemd/user/omarchy-battery-monitor.service" \
  "$HOME/.config/systemd/user/omarchy-battery-monitor.timer" \
  "$HOME/.config/systemd/user/omarchy-recover-internal-monitor.service"
for dir in timers.target.wants graphical-session-pre.target.wants; do
  rm -f "$HOME/.config/systemd/user/$dir/omarchy-battery-monitor.timer" \
    "$HOME/.config/systemd/user/$dir/omarchy-recover-internal-monitor.service"
done
systemctl --user daemon-reload 2>/dev/null
