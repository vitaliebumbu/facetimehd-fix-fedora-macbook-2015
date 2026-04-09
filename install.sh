#!/bin/bash
#
# FaceTime HD Camera Fix on Fedora running on MacBook Pro 2015
#
# Self-contained installer. Builds the patched FaceTime HD driver
# from the sources vendored in this repository, downloads the camera
# firmware blob from Apple's update servers, and loads the module.
#
# Run from a checkout of this repo:
#
#   sudo bash install.sh
#
# Or run remotely:
#
#   curl -fsSL https://raw.githubusercontent.com/vitaliebumbu/facetimehd-fix-fedora-macbook-2015/main/install-remote.sh | sudo bash
#
# This repository contains code from patjak/facetimehd and
# patjak/facetimehd-firmware (GPL-2.0). See NOTICE and AUTHORS for
# attribution, and CHANGES.md for the modifications made here.
#
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DRIVER_DIR="$SCRIPT_DIR/driver"
FIRMWARE_DIR="$SCRIPT_DIR/firmware-extractor"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo -e "${BOLD}"
echo "  ┌──────────────────────────────────────────────────────────┐"
echo "  │  FaceTime HD Camera Fix on Fedora — MacBook Pro 2015     │"
echo "  │  github.com/vitaliebumbu/facetimehd-fix-fedora-macbook-2015 │"
echo "  └──────────────────────────────────────────────────────────┘"
echo -e "${NC}"

# ── Sanity checks ──────────────────────────────────

if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root: sudo bash $0"
fi

if [[ ! -d "$DRIVER_DIR" ]] || [[ ! -d "$FIRMWARE_DIR" ]]; then
    error "Could not find driver/ and firmware-extractor/ next to this script. Run from a full checkout of the repo."
fi

if ! lspci | grep -qi "facetime\|14e4:1570"; then
    error "FaceTime HD camera (Broadcom 1570) not detected. This fix is for MacBooks with the PCIe FaceTime HD camera."
fi

info "FaceTime HD camera detected"

# ── Dependencies ───────────────────────────────────

if command -v dnf &>/dev/null; then
    info "Installing dependencies (dnf)..."
    dnf install -y "kernel-devel-$(uname -r)" make gcc curl xz cpio
elif command -v apt-get &>/dev/null; then
    info "Installing dependencies (apt)..."
    apt-get update -qq
    apt-get install -y "linux-headers-$(uname -r)" make gcc curl xz-utils cpio
elif command -v pacman &>/dev/null; then
    info "Installing dependencies (pacman)..."
    pacman -S --noconfirm linux-headers make gcc curl xz cpio
elif command -v zypper &>/dev/null; then
    info "Installing dependencies (zypper)..."
    zypper install -y kernel-devel make gcc curl xz cpio
else
    warn "Unknown package manager — make sure kernel headers, make, gcc, curl, xz, and cpio are installed."
fi

if [[ ! -d "/lib/modules/$(uname -r)/build" ]]; then
    error "Kernel headers not found for $(uname -r). Install them and re-run this script."
fi

# ── Step 1: Firmware ───────────────────────────────

info "Downloading and extracting camera firmware from Apple's update servers..."
info "(This step uses the vendored extractor script in firmware-extractor/.)"
cd "$FIRMWARE_DIR"
make clean 2>/dev/null || true
make
make install
info "Firmware installed to /lib/firmware/facetimehd/"

# ── Step 2: Driver ─────────────────────────────────

info "Building patched driver from driver/..."
cd "$DRIVER_DIR"
make clean 2>/dev/null || true
make

info "Installing driver..."
make install
depmod -a

# ── Step 3: Configure ──────────────────────────────

info "Configuring module..."

# Apple's bdc_pci grabs the device first if loaded — block it.
echo "blacklist bdc_pci" > /etc/modprobe.d/blacklist-facetimehd.conf

# Auto-load on boot.
mkdir -p /etc/modules-load.d
echo "facetimehd" > /etc/modules-load.d/facetimehd.conf

# ── Step 4: Sleep/wake service ─────────────────────

if [[ -f "$SCRIPT_DIR/scripts/facetimehd-unload.service" ]]; then
    info "Installing sleep/wake service..."
    cp "$SCRIPT_DIR/scripts/facetimehd-unload.service" /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable facetimehd-unload.service
fi

# ── Step 5: Load module ────────────────────────────

info "Loading module..."
modprobe -r facetimehd 2>/dev/null || true
sleep 1
modprobe facetimehd

# ── Step 6: Verify ─────────────────────────────────

echo ""
if [[ -e /dev/video0 ]]; then
    echo -e "${GREEN}${BOLD}  SUCCESS! Camera is working at /dev/video0${NC}"
    echo ""
    echo "  Test it:"
    echo "    ffplay /dev/video0"
    echo "    # or open GNOME Camera / Cheese / Zoom"
    echo ""
    echo "  To uninstall later:"
    echo "    sudo bash $SCRIPT_DIR/uninstall.sh"
else
    warn "No /dev/video0 found. Check dmesg for errors:"
    dmesg | grep -i facetime | tail -10
fi

echo ""
info "Done!"
