#!/bin/bash
# Send a playerctl command to the ONE player the waybar web-media widget is
# showing — not to every non-excluded player at once.
#
# Replaces `playerctl --ignore-player Feishin,typhoon <cmd>` in that widget's
# on-click: this form toggles all remaining players together, so pausing
# Spotifast also unpaused a paused browser player. Selection mirrors
# mediaplayer.py's get_first_playing_player: a playing player wins, otherwise
# a paused one, otherwise whatever is left. Feishin and typhoon stay excluded —
# they have their own widgets.
#
# usage: media-control.sh <playerctl command>   (play-pause | next | previous)

set -u
action="${1:?usage: media-control.sh <play-pause|next|previous>}"
excluded="Feishin,typhoon"

playing=""
paused=""
fallback=""

# tac: prefer the most recently listed player, like mediaplayer.py does when
# it walks its players in reverse.
while IFS= read -r name; do
  case ",$excluded," in *",$name,"*) continue ;; esac
  [ -z "$fallback" ] && fallback="$name"
  status="$(playerctl --player "$name" status 2>/dev/null)" || status=""
  case "$status" in
    Playing) playing="$name"; break ;;
    Paused) [ -z "$paused" ] && paused="$name" ;;
  esac
done < <(tac < <(playerctl --list-all 2>/dev/null))

target="${playing:-${paused:-$fallback}}"
[ -n "$target" ] || exit 0
exec playerctl --player "$target" "$action"
