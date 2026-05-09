#!/bin/bash

EVENTS=$(gcalcli agenda --nocolor --nolineart --tsv "now" "$(date +%Y-%m-%d) 23:59" 2>/dev/null)

if [ -z "$EVENTS" ]; then
    echo '{"text": "", "tooltip": "No more meetings today"}'
    exit 0
fi

NEXT=$(echo "$EVENTS" | head -1)
START_TIME=$(echo "$NEXT" | awk -F'\t' '{print $2}')
END_TIME=$(echo "$NEXT" | awk -F'\t' '{print $4}')
TITLE=$(echo "$NEXT" | awk -F'\t' '{print $5}')
TOTAL=$(echo "$EVENTS" | wc -l | tr -d ' ')

TOOLTIP=$(printf "Next: %s (%s–%s)" "$TITLE" "$START_TIME" "$END_TIME")
if [ "$TOTAL" -gt 1 ]; then
    TOOLTIP=$(printf "%s\n+%d more today" "$TOOLTIP" "$((TOTAL - 1))")
fi

jq -n \
    --arg text "󰃭 ${START_TIME} ${TITLE}" \
    --arg tooltip "$TOOLTIP" \
    '{"text": $text, "tooltip": $tooltip}'
