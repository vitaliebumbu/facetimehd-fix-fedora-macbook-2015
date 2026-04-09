#!/bin/bash
#
# FaceTime HD Camera Fix on Fedora running on MacBook Pro 2015
# One-line remote installer.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/vitaliebumbu/facetimehd-fix-fedora-macbook-2015/main/install-remote.sh | sudo bash
#
# This script downloads a fresh copy of this repository (which is
# self-contained — it does not pull from any other GitHub project)
# and runs install.sh from it.
#
# This repository contains code from patjak/facetimehd and
# patjak/facetimehd-firmware (GPL-2.0). See NOTICE and AUTHORS for
# attribution, and CHANGES.md for the modifications made here.
#
set -e

REPO_URL="https://github.com/vitaliebumbu/facetimehd-fix-fedora-macbook-2015.git"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo -e "${BOLD}"
echo "  ┌──────────────────────────────────────────────────────────┐"
echo "  │  FaceTime HD Camera Fix on Fedora — MacBook Pro 2015     │"
echo "  │  One-line remote installer                               │"
echo "  └──────────────────────────────────────────────────────────┘"
echo -e "${NC}"

if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root. Try:\n  curl -fsSL https://raw.githubusercontent.com/vitaliebumbu/facetimehd-fix-fedora-macbook-2015/main/install-remote.sh | sudo bash"
fi

# git is needed just for the clone — install it if missing.
if ! command -v git &>/dev/null; then
    if   command -v dnf      &>/dev/null; then dnf install -y git
    elif command -v apt-get  &>/dev/null; then apt-get update -qq && apt-get install -y git
    elif command -v pacman   &>/dev/null; then pacman -S --noconfirm git
    elif command -v zypper   &>/dev/null; then zypper install -y git
    else error "git is required but not installed."
    fi
fi

WORK_DIR="$(mktemp -d /tmp/facetimehd-fix.XXXXXX)"
trap 'rm -rf "$WORK_DIR"' EXIT

info "Fetching repository..."
git clone --depth 1 "$REPO_URL" "$WORK_DIR/repo"

info "Running installer..."
bash "$WORK_DIR/repo/install.sh"
