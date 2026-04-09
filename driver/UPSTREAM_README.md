# Vendored copy of patjak/facetimehd

This directory is a vendored copy of the
[patjak/facetimehd](https://github.com/patjak/facetimehd) Linux kernel
driver for the Broadcom 1570 PCIe FaceTime HD camera.

It is included here so this repository remains usable even if the
upstream repository disappears.

## Upstream

- Repo:  https://github.com/patjak/facetimehd
- Authors: Patrik Jakobsson, Sven Schnelle, and contributors
- License: GPL-2.0-only

## Modifications in this repo

Four files have been modified to fix a frozen-frame bug on Linux
kernel 6.15+:

- `fthd_v4l2.c`
- `fthd_drv.c`
- `fthd_drv.h`
- `fthd_buffer.h`

Each modified file carries a "Modified ... by vitaliebumbu" notice
at the top of the file listing the changes, as required by GPL-2.0
§2(a). See `../CHANGES.md` for the full description of every change.

All other files are verbatim copies of the upstream sources.

---

## Original upstream README

> facetimehd
> ==========
>
> Linux driver for the Facetime HD (Broadcom 1570) PCIe webcam
> found in recent Macbooks.
>
> This driver is experimental. Use at your own risk.
>
> See the upstream wiki at https://github.com/patjak/bcwc_pcie/wiki
> for more information.
