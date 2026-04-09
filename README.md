# FaceTime HD Camera Fix on Fedora running on MacBook Pro 2015

Fix the **frozen / single-frame FaceTime HD webcam** on **Fedora Linux** (kernel 6.15+) running on an **Apple MacBook Pro 2015**. One command, fully self-contained, no manual patching.

> Keywords: facetime hd camera linux fix, macbook pro 2015 webcam fedora, broadcom 1570 fedora driver, facetimehd kernel 6.15, facetimehd kernel 6.19, macbookpro11,4 camera linux, gnome camera black screen macbook, cheese frozen frame macbook fedora.

```bash
curl -fsSL https://raw.githubusercontent.com/vitaliebumbu/facetimehd-fix-fedora-macbook-2015/main/install-remote.sh | sudo bash
```

That's it. Run the line above on your MacBook running Fedora and the camera will work in GNOME Camera, Cheese, Zoom, OBS, and any other V4L2 application.

---

## What this fixes

The Linux **FaceTime HD camera driver** (`facetimehd`, for the Broadcom 1570 PCIe webcam in 2013-2015 MacBooks) loads fine on modern kernels and creates `/dev/video0`, but the video **freezes after the very first frame**. GNOME Camera shows a still image, Cheese is stuck, Zoom shows a black or frozen preview, and `dmesg` is suspiciously quiet.

This is a regression that affects **kernel 6.15 and newer**, including Fedora 41/42/43, Ubuntu 24.10+, Arch, openSUSE Tumbleweed, and any other distro with a recent kernel.

This repository ships a **self-contained, patched build** of the driver that fixes the bug.

## Why a frozen image?

Three interacting bugs in the upstream driver break streaming on modern kernels. The full technical write-up is in [`CHANGES.md`](CHANGES.md), but the short version:

1. **Buffer-recycling deadlock** — `buf_queue()` blocks for up to 2 seconds while holding the vb2 queue lock, which starves `DQBUF` and freezes the pipeline after one frame.
2. **Missing buffer timestamps** — modern V4L2 consumers (PipeWire, GStreamer, GNOME Camera) interpret all-zero timestamps as a stalled stream and stop reading.
3. **Variable shadowing in the IRQ handler** — the safety counter in `fthd_irq_work()` is silently broken because an inner loop reuses the outer loop's index.

The patched driver in this repo schedules buffer submission via a workqueue (so it can block without holding the vb2 lock), stamps every buffer with `ktime_get_ns()` and a sequence number, and fixes the IRQ handler.

## Tested hardware and software

| Component | Details |
|---|---|
| **Machine** | Apple MacBook Pro Mid-2015, 15", Retina (MacBookPro11,4) |
| **CPU** | Intel Core i7-4870HQ @ 2.50 GHz |
| **RAM** | 16 GB DDR3L |
| **GPU** | Intel Iris Pro |
| **Camera** | Broadcom 720p FaceTime HD (PCIe `14e4:1570`) |
| **OS** | Fedora Linux 43 Workstation |
| **Kernel** | 6.19.10-200.fc43.x86_64 |
| **Desktop** | GNOME on Wayland |

Should work on any distro with kernel 6.15+ on these MacBook models:

- MacBookPro11,1 / 11,2 / 11,3 / 11,4 / 11,5 (2013–2015)
- MacBookPro12,1 (2015)
- MacBookAir6,1 / 6,2 / 7,1 / 7,2 (2013–2015)
- Anything else with PCI device `14e4:1570`

Verify your camera with:

```bash
lspci | grep -i facetime
# Should print: Broadcom Inc. 720p FaceTime HD Camera
```

## Installation

### Option 1 — One-line install (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/vitaliebumbu/facetimehd-fix-fedora-macbook-2015/main/install-remote.sh | sudo bash
```

The remote installer clones this repo into a temp directory and runs `install.sh`. It does **not** pull from any other GitHub project — everything it needs is vendored here.

### Option 2 — Clone first, then install

If you want to read the code before running it:

```bash
git clone https://github.com/vitaliebumbu/facetimehd-fix-fedora-macbook-2015.git
cd facetimehd-fix-fedora-macbook-2015
sudo bash install.sh
```

### What the installer does

1. Installs build dependencies (`kernel-devel`, `gcc`, `make`, `curl`, `xz`, `cpio`).
2. Runs the firmware extractor in [`firmware-extractor/`](firmware-extractor/), which downloads Apple's official macOS update package and pulls the camera firmware blob out of it. The firmware is **not** stored in this repo — it's fetched directly from Apple's CDN at install time.
3. Builds the patched kernel module from the sources in [`driver/`](driver/).
4. Installs the module, blacklists the conflicting `bdc_pci` module, and configures auto-load on boot.
5. Installs a systemd service that survives suspend/resume.
6. Loads the module and verifies `/dev/video0` exists.

### Verify it worked

```bash
ls /dev/video0          # should exist
ffplay /dev/video0      # should show live video
```

Or just open GNOME Camera / Cheese / Zoom.

## Uninstall

```bash
sudo bash uninstall.sh
```

Removes the kernel module, configuration files, and the sleep/wake service. The firmware in `/lib/firmware/facetimehd/` is left in place.

## Troubleshooting

### Camera not detected

```bash
lspci | grep -i facetime
```

If this is empty, the PCI hardware itself isn't being seen — usually a BIOS/EFI issue, not a driver issue.

### Module won't load

```bash
sudo modprobe facetimehd
sudo dmesg | grep -i facetime
```

If you see firmware errors, the firmware extractor probably failed. Re-run `sudo bash install.sh` and watch the output of the firmware step.

### `1871_01XX.dat` warning in dmesg

```
Direct firmware load for facetimehd/1871_01XX.dat failed with error -2
```

This is **cosmetic**. The camera works without the per-sensor calibration file. Colors may be slightly off. See the [upstream wiki](https://github.com/patjak/facetimehd/wiki/Extracting-the-sensor-calibration-files) for how to extract it.

### Image is green / inverted after install

Do a full **power off** (not reboot) and boot back up. The ISP firmware sometimes gets into a bad state that only a cold boot clears.

### Camera stops working after suspend

The installer enables a systemd service that unloads and reloads the module across suspend cycles. If it didn't run for some reason:

```bash
sudo systemctl enable --now facetimehd-unload.service
```

## Repository layout

```
.
├── README.md              ← this file
├── LICENSE                ← GPL-2.0
├── NOTICE                 ← attribution to upstream projects
├── AUTHORS                ← list of authors and contributors
├── CHANGES.md             ← description of every change in this repo
├── install.sh             ← local installer
├── install-remote.sh      ← one-line remote installer
├── uninstall.sh           ← removes the driver
├── driver/                ← vendored patjak/facetimehd, with patches
│   ├── UPSTREAM_README.md ← what's in this dir, what's modified
│   └── ...
├── firmware-extractor/    ← vendored patjak/facetimehd-firmware
│   ├── UPSTREAM_README.md ← what's in this dir
│   └── ...
└── scripts/
    └── facetimehd-unload.service
```

## Credits and license

This repository builds on years of work by **Patrik Jakobsson**, **Sven Schnelle**, and the contributors to:

- [patjak/facetimehd](https://github.com/patjak/facetimehd) — the V4L2 kernel driver
- [patjak/facetimehd-firmware](https://github.com/patjak/facetimehd-firmware) — the firmware extraction tooling

Both projects are **GPL-2.0**, and so is this one. All upstream copyright notices are preserved in the vendored source files. Files that have been modified in this repo carry a "Modified by vitaliebumbu" notice at the top, in compliance with GPL-2.0 §2(a).

See [`NOTICE`](NOTICE), [`AUTHORS`](AUTHORS), and [`CHANGES.md`](CHANGES.md) for full attribution and a description of every change.

This repository exists so that people on old MacBooks can fix their cameras with one command, **and** so the fix keeps working even if the upstream repos disappear. Every file the build needs is vendored here.

### Why a separate repo?

There is an earlier, smaller version of this fix at [vitaliebumbu/facetimehd-fix](https://github.com/vitaliebumbu/facetimehd-fix) which only ships the patches and clones upstream at install time. This repository is the **self-contained successor**: it vendors the full upstream sources so it has zero external dependencies.

## Related upstream issues

- [patjak/facetimehd#315](https://github.com/patjak/facetimehd/issues/315) — Frozen image on kernels 6.15+
- [patjak/facetimehd#303](https://github.com/patjak/facetimehd/issues/303) — Build fixes for kernel 6.13+

## License

GPL-2.0-only. See [LICENSE](LICENSE).
