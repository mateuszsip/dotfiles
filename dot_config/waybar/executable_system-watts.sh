#!/bin/bash
# Outputs JSON for Waybar: system power draw with CPU/GPU tooltip.
# Apple Silicon (macsmc-battery + macsmc_hwmon) and Intel/NVIDIA laptops.

# Auto-detect battery supply (BAT0, BATT, macsmc-battery, ...)
for ps in /sys/class/power_supply/*; do
  if [ "$(cat "$ps/type" 2>/dev/null)" = "Battery" ]; then BAT="$ps"; break; fi
done
BAT="${BAT:-/sys/class/power_supply/BAT0}"

STATUS=$(cat "$BAT/status" 2>/dev/null)

# SoC total power on Apple Silicon (macsmc_hwmon/power1_input, in µW).
SOC_UW=0
for n in /sys/class/hwmon/hwmon*/name; do
  if [ "$(cat "$n" 2>/dev/null)" = "macsmc_hwmon" ]; then
    SOC_UW=$(cat "$(dirname "$n")/power1_input" 2>/dev/null || echo 0); break
  fi
done

# Find a discrete GPU power sensor (skip SoC/battery pseudo-hwmons).
GPU_UW=0
for h in /sys/class/hwmon/hwmon*/power1_input; do
  name=$(cat "$(dirname "$h")/name" 2>/dev/null)
  case "$name" in macsmc_battery|macsmc_ac|macsmc_hwmon|tps6598x*|tas2764|apple*) continue;; esac
  GPU_UW=$(cat "$h" 2>/dev/null || echo 0); [ "$GPU_UW" != "0" ] && break
done
GPU_W=$(awk "BEGIN { printf \"%.0f\", $GPU_UW / 1000000 }")

ENERGY_NOW=$(cat "$BAT/energy_now" 2>/dev/null || echo 0)
ENERGY_FULL=$(cat "$BAT/energy_full" 2>/dev/null || echo 1)
HEALTH=$(awk "BEGIN { printf \"%.0f\", $ENERGY_FULL / $(cat "$BAT/energy_full_design" 2>/dev/null || echo 1) * 100 }")
CYCLES=$(cat "$BAT/cycle_count" 2>/dev/null || echo "?")

if [ "$STATUS" = "Discharging" ]; then
    POWER_UW=$(cat "$BAT/power_now" 2>/dev/null || echo 0)
    # macsmc-battery reports signed µW (negative while discharging); take abs.
    POWER_UW=${POWER_UW#-}
    TOTAL_W=$(awk "BEGIN { printf \"%.0f\", $POWER_UW / 1000000 }")
    CPU_W=$(( TOTAL_W > GPU_W ? TOTAL_W - GPU_W : 0 ))
    TEXT="${TOTAL_W}W"
    TOOLTIP="CPU ~${CPU_W}W · GPU ${GPU_W}W\\nHealth: ${HEALTH}% · ${CYCLES} cycles"
else
    # Plugged in
    if [ "$SOC_UW" != "0" ] && [ -n "$SOC_UW" ]; then
        TOTAL_W=$(awk "BEGIN { printf \"%.0f\", $SOC_UW / 1000000 }")
    else
        RAPL=/sys/class/powercap/intel-rapl/intel-rapl:0/energy_uj
        if E1=$(cat "$RAPL" 2>/dev/null); then
            sleep 1
            E2=$(cat "$RAPL" 2>/dev/null) || { echo '{"text":"","tooltip":""}'; exit 0; }
            CPU_W=$(awk "BEGIN { printf \"%.0f\", ($E2 - $E1) / 1000000 }")
        else
            CPU_W=0
        fi
        TOTAL_W=$(( CPU_W + GPU_W ))
    fi
    TEXT="${TOTAL_W}W"
    TOOLTIP="CPU ${CPU_W:-0}W · GPU ${GPU_W}W\\nHealth: ${HEALTH}% · ${CYCLES} cycles"
fi

printf '{"text":"%s","tooltip":"%s"}\n' "$TEXT" "$TOOLTIP"