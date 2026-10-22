#!/usr/bin/env bash
count=$(cat /tmp/ai-count 2>/dev/null)
if [ -n "$count" ] && [ "$count" -gt 0 ] 2>/dev/null; then
    echo '{"text": "󰚩", "tooltip": "AI finished — click to dismiss", "class": "active"}'
else
    echo '{"text": "󰚩", "class": ""}'
fi
