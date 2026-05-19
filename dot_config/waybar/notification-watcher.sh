#!/bin/bash
# Counts incoming notifications via D-Bus and signals waybar to refresh.
# Persists count in /tmp/mako-unread-count; reset by dismiss action.

COUNTER_FILE=/tmp/mako-unread-count
[ -f "$COUNTER_FILE" ] || echo 0 > "$COUNTER_FILE"

dbus-monitor --session \
    "type='method_call',interface='org.freedesktop.Notifications',member='Notify'" \
    2>/dev/null | \
grep --line-buffered "^method call" | \
while read -r _; do
    count=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)
    echo $((count + 1)) > "$COUNTER_FILE"
    pkill -SIGRTMIN+12 waybar
done
