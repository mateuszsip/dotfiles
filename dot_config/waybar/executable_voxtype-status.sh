#!/bin/bash
# Waybar status for voxtype, merged with the default microphone's mute state.
#
# voxtype only reports its own state (idle/recording/transcribing), so a muted
# microphone would look exactly like a working one. Polled (interval 1) rather
# than --follow for that reason: muting happens outside voxtype.

set -uo pipefail

runtime="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
state=$(cat "$runtime/voxtype/state" 2>/dev/null) || state=stopped

muted=false
if command -v wpctl >/dev/null 2>&1; then
  wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -q '\[MUTED\]' && muted=true
elif command -v pactl >/dev/null 2>&1; then
  [ "$(pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null)" = "Mute: yes" ] && muted=true
fi

case "$state" in
  recording)    icon="󰻂"; action="Recording";         class=recording;    known=true ;;
  transcribing) icon="󱑽"; action="Transcribing";      class=transcribing; known=true ;;
  idle)         icon="󰍬"; action="Dictation ready";   class=idle;         known=true ;;
  *)            icon="󰍭"; action="Voxtype not running"; class=stopped;    known=false ;;
esac

if [ "$muted" = true ]; then
  icon=""
  class=muted
  if [ "$state" = recording ]; then
    action="Recording with the microphone muted"
  else
    action="Microphone muted"
  fi
  hint="Click to unmute"
elif [ "$known" = false ]; then
  hint="Right-click for audio controls"
else
  hint="Click to mute"
fi

printf '{"text":"%s","class":"%s","tooltip":"%s\\n%s"}\n' "$icon" "$class" "$action" "$hint"
