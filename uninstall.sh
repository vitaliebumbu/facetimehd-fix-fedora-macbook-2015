#!/bin/bash
#
# FaceTime HD Camera Fix on Fedora running on MacBook Pro 2015
# Uninstaller — removes the patched driver and configuration.
#
set -e

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root: sudo bash $0"
    exit 1
fi

echo "Unloading module..."
modprobe -r facetimehd 2>/dev/null || true

echo "Removing module..."
rm -f "/lib/modules/$(uname -r)/extra/facetimehd.ko"*
rm -f "/lib/modules/$(uname -r)/updates/facetimehd.ko"*
depmod -a

echo "Removing module configuration..."
rm -f /etc/modules-load.d/facetimehd.conf
rm -f /etc/modprobe.d/blacklist-facetimehd.conf

echo "Removing sleep/wake service..."
systemctl disable facetimehd-unload.service 2>/dev/null || true
rm -f /etc/systemd/system/facetimehd-unload.service
systemctl daemon-reload 2>/dev/null || true

echo "Done. The facetimehd driver and its configuration have been removed."
echo "Firmware at /lib/firmware/facetimehd/ was left in place."
