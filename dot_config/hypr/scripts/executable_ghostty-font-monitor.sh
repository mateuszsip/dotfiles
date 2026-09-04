#!/bin/bash
# Runs at login (see hypr/autostart.conf). Watches Hyprland's event socket for
# monitor plug/unplug and re-applies the Ghostty font-size drop-in via
# ghostty-font-size.sh. Survives Hyprland restarts by re-resolving the socket.

APPLY="$HOME/.config/hypr/scripts/ghostty-font-size.sh"

bash "$APPLY"

while true; do
    sig=${HYPRLAND_INSTANCE_SIGNATURE:-$(ls -t "$XDG_RUNTIME_DIR/hypr" 2>/dev/null | grep -v '^lock$' | head -n1)}
    sock="$XDG_RUNTIME_DIR/hypr/$sig/.socket2.sock"

    if [[ -n $sig && -S $sock ]]; then
        socat -U - "UNIX-CONNECT:$sock" | while read -r line; do
            case $line in
                monitoradded*|monitorremoved*) bash "$APPLY" ;;
            esac
        done
    fi

    sleep 2
done
