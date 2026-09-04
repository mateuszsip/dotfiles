#!/bin/bash
# Writes the Ghostty font-size drop-in (~/.config/ghostty/display.conf) for the
# current monitor setup: 12pt with only the internal panel, 14pt when an
# external monitor is connected. New Ghostty windows pick the drop-in up
# automatically; already-open ones refresh with ctrl+shift+, (reload_config).

set -euo pipefail

INTERNAL_PT=12   # Lenovo eDP-1 panel
EXTERNAL_PT=14   # external monitor (e.g. the Xiaomi 1440p)
DROP_IN="$HOME/.config/ghostty/display.conf"

desired="font-size = $INTERNAL_PT"
if hyprctl monitors -j | jq -e '[.[] | select(.name != "eDP-1" and .disabled != true)] | length > 0' >/dev/null; then
    desired="font-size = $EXTERNAL_PT"
fi

if [[ ! -f $DROP_IN || $(<"$DROP_IN") != "$desired" ]]; then
    mkdir -p "$(dirname "$DROP_IN")"
    printf '%s\n' "$desired" >"$DROP_IN"
fi
