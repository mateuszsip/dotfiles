#!/bin/bash
# Shows system power draw:
# - When discharging: reads battery power_now (accurate total draw)
# - When plugged in: samples Intel RAPL package energy over 1s

STATUS=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null)

if [ "$STATUS" = "Discharging" ]; then
    POWER=$(cat /sys/class/power_supply/BAT0/power_now 2>/dev/null)
    [ -z "$POWER" ] && exit 0
    awk "BEGIN { printf \"%.0fW\n\", $POWER / 1000000 }"
    exit 0
fi

RAPL=/sys/class/powercap/intel-rapl/intel-rapl:0/energy_uj
E1=$(cat "$RAPL" 2>/dev/null) || exit 0
sleep 1
E2=$(cat "$RAPL" 2>/dev/null) || exit 0

awk "BEGIN { printf \"%.0fW\n\", ($E2 - $E1) / 1000000 }"
