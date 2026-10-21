#!/bin/bash
# Waybar indicator: is the idle lock (hypridle) running?
# Prints JSON for the waybar custom module.

if pgrep -x hypridle >/dev/null; then
  echo '{"text": ""}'
else
  echo '{"text": "󱫖", "tooltip": "Idle lock disabled", "class": "active"}'
fi
