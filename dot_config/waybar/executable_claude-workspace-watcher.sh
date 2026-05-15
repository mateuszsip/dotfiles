#!/usr/bin/env bash
socket="/run/user/1000/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
socat -U - UNIX-CONNECT:"$socket" | while IFS= read -r line; do
    event="${line%%>>*}"
    data="${line#*>>}"
    if [ "$event" = "workspace" ]; then
        target=$(cat /tmp/claude-workspace 2>/dev/null)
        if [ -n "$target" ] && [ "$data" = "$target" ]; then
            rm -f /tmp/claude-count /tmp/claude-workspace
            pkill -SIGRTMIN+11 waybar
        fi
    fi
done
