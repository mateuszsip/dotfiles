#!/bin/bash
# Outputs JSON for Waybar: system power draw with CPU/GPU tooltip

STATUS=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null)
GPU_UW=$(cat /sys/class/hwmon/hwmon5/power1_input 2>/dev/null || echo 0)
GPU_W=$(awk "BEGIN { printf \"%.0f\", $GPU_UW / 1000000 }")

ENERGY_NOW=$(cat /sys/class/power_supply/BAT0/energy_now 2>/dev/null || echo 0)
ENERGY_FULL=$(cat /sys/class/power_supply/BAT0/energy_full 2>/dev/null || echo 1)
HEALTH=$(awk "BEGIN { printf \"%.0f\", $ENERGY_FULL / $(cat /sys/class/power_supply/BAT0/energy_full_design) * 100 }")
CYCLES=$(cat /sys/class/power_supply/BAT0/cycle_count 2>/dev/null || echo "?")

if [ "$STATUS" = "Discharging" ]; then
    POWER_UW=$(cat /sys/class/power_supply/BAT0/power_now 2>/dev/null || echo 0)
    TOTAL_W=$(awk "BEGIN { printf \"%.0f\", $POWER_UW / 1000000 }")
    CPU_W=$(( TOTAL_W > GPU_W ? TOTAL_W - GPU_W : 0 ))
    TEXT="${TOTAL_W}W"
    TOOLTIP="CPU ~${CPU_W}W · GPU ${GPU_W}W\nHealth: ${HEALTH}% · ${CYCLES} cycles"
else
    RAPL=/sys/class/powercap/intel-rapl/intel-rapl:0/energy_uj
    E1=$(cat "$RAPL" 2>/dev/null) || { echo '{"text":"","tooltip":""}'; exit 0; }
    sleep 1
    E2=$(cat "$RAPL" 2>/dev/null) || { echo '{"text":"","tooltip":""}'; exit 0; }
    CPU_W=$(awk "BEGIN { printf \"%.0f\", ($E2 - $E1) / 1000000 }")
    TOTAL_W=$(( CPU_W + GPU_W ))
    TEXT="${TOTAL_W}W"
    TOOLTIP="CPU ${CPU_W}W · GPU ${GPU_W}W\nHealth: ${HEALTH}% · ${CYCLES} cycles"
fi

printf '{"text":"%s","tooltip":"%s"}\n' "$TEXT" "$TOOLTIP"
