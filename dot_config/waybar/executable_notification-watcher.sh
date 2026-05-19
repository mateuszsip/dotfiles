#!/bin/bash
# Counts incoming notifications via D-Bus and signals waybar to refresh.
# Persists count in /tmp/mako-unread-count; reset by dismiss action.
# Skips notifications whose summary contains "Screenshot".

COUNTER_FILE=/tmp/mako-unread-count
[ -f "$COUNTER_FILE" ] || echo 0 > "$COUNTER_FILE"

dbus-monitor --session \
    "type='method_call',interface='org.freedesktop.Notifications',member='Notify'" \
    2>/dev/null | \
awk '
/^method call/ {
    in_notify = 1
    str_count = 0
    next
}
in_notify && /string "/ {
    str_count++
    if (str_count == 3) {
        gsub(/.*string "/, "")
        gsub(/".*/, "")
        summary = $0
        if (index(summary, "Screenshot") == 0) {
            cmd = "n=$(cat /tmp/mako-unread-count 2>/dev/null || echo 0); echo $((n+1)) > /tmp/mako-unread-count; pkill -SIGRTMIN+12 waybar"
            system(cmd)
        }
        in_notify = 0
    }
}
'
