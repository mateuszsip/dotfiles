#!/usr/bin/env bash

# Find the Hyprland workspace containing the terminal running this Claude Code session
claude_ws=$(python3 -c "
import json, subprocess, os

def get_ppid(pid):
    try:
        with open(f'/proc/{pid}/status') as f:
            for line in f:
                if line.startswith('PPid:'):
                    return int(line.split()[1])
    except:
        pass
    return None

result = subprocess.run(['hyprctl', 'clients', '-j'], capture_output=True, text=True)
clients = json.loads(result.stdout)
pid_to_ws = {c['pid']: c['workspace']['id'] for c in clients if c.get('pid')}

pid = os.getpid()
for _ in range(20):
    if pid in pid_to_ws:
        print(pid_to_ws[pid])
        break
    ppid = get_ppid(pid)
    if not ppid or ppid <= 1:
        break
    pid = ppid
" 2>/dev/null)

active_ws=$(hyprctl activeworkspace -j | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])")

# Don't notify if user is already on Claude's workspace
if [ -n "$claude_ws" ] && [ "$active_ws" = "$claude_ws" ]; then
    exit 0
fi

count=$(cat /tmp/claude-count 2>/dev/null || echo 0)
echo $((count + 1)) > /tmp/claude-count
echo "${claude_ws:-$active_ws}" > /tmp/claude-workspace
pkill -SIGRTMIN+11 waybar
