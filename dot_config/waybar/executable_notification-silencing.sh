#!/bin/bash
# Waybar indicator: are notifications silenced (mako do-not-disturb mode)?
# Prints JSON for the waybar custom module.

if makoctl mode | grep -q 'do-not-disturb'; then
  echo '{"text": "󰂛", "tooltip": "Notifications silenced", "class": "active"}'
else
  echo '{"text": ""}'
fi
