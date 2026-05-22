#!/bin/bash
# Counts incoming notifications via D-Bus and signals waybar to refresh.
# Persists count in /tmp/mako-unread-count; reset by dismiss action.
# Skips:
#   - low-urgency notifications (byte 0) — omarchy system toggles, etc.
#   - app_name containing "playerctld" — song change notifications
#   - summary containing "Screenshot"

COUNTER_FILE=/tmp/mako-unread-count
[ -f "$COUNTER_FILE" ] || echo 0 > "$COUNTER_FILE"

COUNT_CMD="n=\$(cat /tmp/mako-unread-count 2>/dev/null || echo 0); echo \$((n+1)) > /tmp/mako-unread-count; pkill -SIGRTMIN+12 waybar"

dbus-monitor --session \
    "type='method_call',interface='org.freedesktop.Notifications',member='Notify'" \
    2>/dev/null | \
awk -v count_cmd="$COUNT_CMD" '
/^method call/ {
    if (pending) { system(count_cmd); }
    in_notify  = 1
    str_count  = 0
    app_name   = ""
    summary    = ""
    pending    = 0
    saw_urgency = 0
    next
}
in_notify && /string "/ {
    str_count++
    gsub(/.*string "/, "")
    gsub(/".*/, "")
    if (str_count == 1) {
        app_name = $0
    } else if (str_count == 3) {
        summary = $0
        if (index(app_name, "playerctld") == 0 && index(summary, "Screenshot") == 0)
            pending = 1
    } else if (str_count > 3 && $0 == "urgency") {
        saw_urgency = 1
    }
}
in_notify && saw_urgency && /byte / {
    gsub(/.*byte /, "")
    if ($0 + 0 == 0) pending = 0
    saw_urgency = 0
    if (pending) { system(count_cmd); pending = 0 }
}
'
