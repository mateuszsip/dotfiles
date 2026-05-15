#!/usr/bin/env bash
count=$(cat /tmp/claude-count 2>/dev/null)
if [ -n "$count" ] && [ "$count" -gt 0 ] 2>/dev/null; then
    echo '{"text": "󰚩", "tooltip": "Claude is done — click to dismiss", "class": "active"}'
else
    echo '{"text": "", "class": ""}'
fi
