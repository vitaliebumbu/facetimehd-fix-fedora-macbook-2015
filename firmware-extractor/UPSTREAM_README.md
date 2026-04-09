# Vendored copy of patjak/facetimehd-firmware

This directory is a vendored copy of the
[patjak/facetimehd-firmware](https://github.com/patjak/facetimehd-firmware)
tooling, used to download and extract the FaceTime HD firmware blob
from Apple's macOS update servers.

It is included here so this repository remains usable even if the
upstream repository disappears.

## What is in this directory

- `Makefile`            — downloads the macOS update package and runs
                          the extractor.
- `extract-firmware.sh` — pulls the firmware bytes out of the macOS
                          camera kernel extension.
- `LICENSE`             — GPL-2.0 (upstream).

## What is NOT in this directory

This directory does **not** contain Apple's proprietary firmware
blob. The blob is downloaded directly from Apple's CDN at install
time by `make`, exactly as the upstream tooling does.

Apple's firmware is not redistributable; only the extraction
tooling (which is GPL-2.0) is vendored here.

## Upstream

- Repo:    https://github.com/patjak/facetimehd-firmware
- Authors: Patrik Jakobsson and contributors
- License: GPL-2.0
