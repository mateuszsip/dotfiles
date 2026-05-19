#!/bin/bash
COUNTER_FILE=/tmp/mako-unread-count
count=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)

if [ "$count" -gt 0 ]; then
    echo $count > /tmp/mako-last-count
    echo "{\"text\": \"󰂚 $count\", \"tooltip\": \"$count notification(s)\nLeft: restore one · Middle: restore all · Right: dismiss all\", \"class\": \"has-notifications\"}"
else
    last=$(cat /tmp/mako-last-count 2>/dev/null || echo 1)
    echo "{\"text\": \"󰂚\", \"tooltip\": \"No active notifications\nLeft: restore one · Middle: restore last $last\", \"class\": \"\"}"
fi
