#!/bin/bash
# Installs the Bosto touchpad USB recovery service system-wide.
# run_onchange_: chezmoi re-runs this whenever this file changes.

set -e

cat > /tmp/bosto-recovery.sh << 'SCRIPT'
#!/bin/bash
# The Bosto touchpad (Apple HID 05ac:0265) reliably fails to enumerate on cold
# boot because it powers up too slowly for the kernel's USB timeout (~112s total
# across 4 retries). This polls until the kernel gives up, then resets the parent
# GenesysLogic hub — equivalent to replugging, but automatic.

BOSTO_ID="05ac:0265"
HUB_VENDOR="05e3"
HUB_PRODUCT="0610"

for i in $(seq 1 150); do
    lsusb -d "$BOSTO_ID" &>/dev/null && exit 0
    sleep 1
done

logger -t bosto-recovery "Bosto touchpad not detected after 150s — resetting USB hub"

for dev in /sys/bus/usb/devices/*/; do
    [[ -f "${dev}idVendor" ]] || continue
    [[ $(cat "${dev}idVendor" 2>/dev/null) == "$HUB_VENDOR" ]] || continue
    [[ $(cat "${dev}idProduct" 2>/dev/null) == "$HUB_PRODUCT" ]] || continue
    hub=$(basename "$dev")
    # 1-1.1.2.3 (4 dots) is the outer hub; 1-1.1.2.3.1 (5 dots) is nested
    [[ $(echo "$hub" | tr -cd '.' | wc -c) -le 4 ]] || continue
    logger -t bosto-recovery "Resetting hub $hub"
    echo -n "$hub" > /sys/bus/usb/drivers/usb/unbind
    sleep 2
    echo -n "$hub" > /sys/bus/usb/drivers/usb/bind
    break
done
SCRIPT

cat > /tmp/bosto-recovery.service << 'SERVICE'
[Unit]
Description=Bosto touchpad USB recovery
After=sysinit.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/bosto-recovery.sh
TimeoutStartSec=180

[Install]
WantedBy=multi-user.target
SERVICE

sudo install -m 755 /tmp/bosto-recovery.sh /usr/local/bin/bosto-recovery.sh
sudo install -m 644 /tmp/bosto-recovery.service /etc/systemd/system/bosto-recovery.service
sudo systemctl daemon-reload
sudo systemctl enable bosto-recovery.service
rm /tmp/bosto-recovery.sh /tmp/bosto-recovery.service

echo "bosto-recovery installed and enabled"
