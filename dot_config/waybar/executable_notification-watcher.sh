#!/bin/bash
# Counts incoming notifications via D-Bus and signals waybar to refresh.
# Persists count in /tmp/mako-unread-count; reset by dismiss action.
# Skips notifications whose app_name contains "playerctld" (song changes)
# or whose summary contains "Screenshot".

COUNTER_FILE=/tmp/mako-unread-count
[ -f "$COUNTER_FILE" ] || echo 0 > "$COUNTER_FILE"

dbus-monitor --session \
    "type='method_call',interface='org.freedesktop.Notifications',member='Notify'" \
    2>/dev/null | \
awk '
/^method call/ {
    in_notify = 1
    str_count = 0
    app_name = ""
    next
}
in_notify && /string "/ {
    str_count++
    gsub(/.*string "/, "")
    gsub(/".*/, "")
    if (str_count == 1) {
        app_name = $0
    }
    if (str_count == 3) {
        summary = $0
        if (index(app_name, "playerctld") == 0 && index(summary, "Screenshot") == 0) {
            cmd = "n=$(cat /tmp/mako-unread-count 2>/dev/null || echo 0); echo $((n+1)) > /tmp/mako-unread-count; pkill -SIGRTMIN+12 waybar"
            system(cmd)
        }
        in_notify = 0
    }
}
'
