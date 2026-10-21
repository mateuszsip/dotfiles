#!/bin/bash
# Waybar indicator: is gpu-screen-recorder running?
# Prints JSON for the waybar custom module.

if pgrep -f "^gpu-screen-recorder" >/dev/null; then
  echo '{"text": "󰻂", "tooltip": "Stop recording", "class": "active"}'
else
  echo '{"text": ""}'
fi
