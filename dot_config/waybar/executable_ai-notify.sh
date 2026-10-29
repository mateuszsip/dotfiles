#!/usr/bin/env bash

dir="${AI_DIR:-${XDG_RUNTIME_DIR:-/tmp}/ai}"

# Find the Hyprland workspace containing the terminal running this session, plus
# the ancestor pids walked to get there. A pid that already has an entry in the
# shared session store means nvim/CodeCompanion reports this chat itself, so the
# legacy counter below would only duplicate it.
found=$(python3 -c "
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

try:
    result = subprocess.run(['hyprctl', 'clients', '-j'], capture_output=True, text=True)
    clients = json.loads(result.stdout or '[]')
except Exception:
    clients = []

# A pid can own several toplevels (ghostty runs every window in one process), so
# a plain pid->client dict picks an arbitrary window. Prefer the most recently
# focused one (lowest focusHistoryID); -1 means never focused.
pid_to_client = {}
for c in clients:
    if not c.get('pid'):
        continue
    hist = c.get('focusHistoryID', -1)
    rank = hist if isinstance(hist, int) and hist >= 0 else 1 << 30
    prev = pid_to_client.get(c['pid'])
    if prev is None or rank < prev[0]:
        pid_to_client[c['pid']] = (rank, c)
pid_to_ws = {p: c['workspace']['id'] for p, (_, c) in pid_to_client.items()}

pid = os.getpid()
pids, ws = [], ''
for _ in range(20):
    pids.append(pid)
    if pid in pid_to_ws:
        ws = pid_to_ws[pid]
        break
    ppid = get_ppid(pid)
    if not ppid or ppid <= 1:
        break
    pid = ppid
print('{}\t{}'.format(ws, ' '.join(map(str, pids))))
" 2>/dev/null)

ai_ws=${found%%$'\t'*}
chain=${found#*$'\t'}

# Store entry for this session: it names the chat and sys-ai jumps to the exact
# buffer, so skip the generic "agent turn finished" counter.
for p in $chain; do
    kill -0 "$p" 2>/dev/null || continue
    for f in "$dir"/*.json; do
        [[ -e $f ]] || continue
        if [ "$(jq -r '.pid // 0' "$f" 2>/dev/null)" = "$p" ]; then
            pkill -SIGRTMIN+11 waybar
            exit 0
        fi
    done
done

active_ws=$(hyprctl activeworkspace -j | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])")

# Don't notify if user is already on Claude's workspace
if [ -n "$ai_ws" ] && [ "$active_ws" = "$ai_ws" ]; then
    exit 0
fi

count=$(cat /tmp/ai-count 2>/dev/null || echo 0)
echo $((count + 1)) > /tmp/ai-count
echo "${ai_ws:-$active_ws}" > /tmp/ai-workspace
pkill -SIGRTMIN+11 waybar
