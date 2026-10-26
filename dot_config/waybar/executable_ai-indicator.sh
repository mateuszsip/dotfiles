#!/usr/bin/env bash
# Waybar `custom/ai`: one line for every AI session that wants attention.
#
# Reads the session store in ${XDG_RUNTIME_DIR}/ai (one JSON file per session,
# written by nvim's utils/cc_notify.lua; the older Claude/opencode notifier
# still tracks a plain count in /tmp/ai-count). Prints waybar JSON, so the
# module needs `"return-type": "json"` and is refreshed with signal 11.
#
# Click actions live in sys-ai:
#   left   jump to the waiting session (menu when several)
#   middle clear finished sessions
#   right  clear everything

set -uo pipefail

dir="${AI_DIR:-${XDG_RUNTIME_DIR:-/tmp}/ai}"
legacy_file=/tmp/ai-count
now=$(date +%s)

waiting=0
finished=0
working=0
lines=()
fields=()

fmt_age() {
  local age=$1
  if ((age < 60)); then
    echo "${age}s"
  elif ((age < 3600)); then
    echo "$((age / 60))m"
  else
    echo "$((age / 3600))h"
  fi
}

icon() {
  case $1 in
  waiting) echo "●" ;;
  done) echo "✓" ;;
  *) echo "·" ;;
  esac
}

for f in "$dir"/*.json; do
  [[ -e $f ]] || continue
  # One value per line: an empty detail must not shift the rest of the row
  # (bash `read` with a tab IFS collapses consecutive delimiters).
  mapfile -t fields < <(jq -r '[
      (.pid // 0),
      (.status // "done"),
      (.tool // "ai"),
      ((.title // "session") | gsub("[\\t\\r\\n]+"; " ")),
      ((.detail // "") | gsub("[\\t\\r\\n]+"; " ")),
      (.ts // 0)
    ][]' "$f" 2>/dev/null)
  if ((${#fields[@]} < 6)); then
    rm -f "$f"
    continue
  fi
  pid=${fields[0]}
  status=${fields[1]}
  tool=${fields[2]}
  title=${fields[3]}
  detail=${fields[4]}
  ts=${fields[5]}

  # A session whose process is gone (SIGKILL, crash, logout) is a ghost.
  # sys-ai writes pid 0 for entries it cannot attribute; keep those.
  if ((pid > 0)) && ! kill -0 "$pid" 2>/dev/null; then
    rm -f "$f"
    continue
  fi

  case $status in
  waiting) waiting=$((waiting + 1)) ;;
  done) finished=$((finished + 1)) ;;
  *) working=$((working + 1)) ;;
  esac

  age=$(fmt_age $((now - ts)))
  [[ -n $detail ]] && detail=" — $detail"
  lines+=("$(icon "$status") $title$detail · $tool · $age")
done

# Claude Code / opencode still report through ai-notify.sh. Treat their
# counter as one finished session until they move to the store too.
legacy=$(cat "$legacy_file" 2>/dev/null || echo 0)
[[ $legacy =~ ^[0-9]+$ ]] || legacy=0
if ((legacy > 0)); then
  finished=$((finished + legacy))
  lines+=("✓ agent turn finished · claude/opencode · $legacy pending")
fi

pending=$((waiting + finished))
if ((waiting > 0)); then
  class=waiting
elif ((finished > 0)); then
  class="done"
elif ((working > 0)); then
  class=working
else
  class=idle
fi

if ((pending > 0)); then
  text="󰚩 $pending"
else
  text="󰚩"
fi

if ((${#lines[@]} > 0)); then
  tooltip=$(printf '%s\n' "${lines[@]}" | jq -Rsr 'rtrimstr("\n")')
else
  tooltip="No AI sessions waiting"
fi

jq -cn --arg text "$text" --arg tooltip "$tooltip" --arg class "$class" \
  '{text: $text, tooltip: $tooltip, class: $class}'
