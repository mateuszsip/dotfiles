#!/usr/bin/env bash
count=$(cat /tmp/claude-count 2>/dev/null || echo 0)
echo $((count + 1)) > /tmp/claude-count
hyprctl activeworkspace -j | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])" > /tmp/claude-workspace
pkill -SIGRTMIN+11 waybar
