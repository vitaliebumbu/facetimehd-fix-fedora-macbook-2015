# Changes Made in This Repository

This file lists modifications made to the upstream
[patjak/facetimehd](https://github.com/patjak/facetimehd) driver in
this repository, in compliance with GPL-2.0 §2(a).

## 2026 — Frozen-frame fix for kernel 6.15+

The upstream driver loads on kernel 6.15+ and creates `/dev/video0`,
but the video stream freezes after a single frame. Three interacting
bugs in the upstream driver cause this on modern kernels:

### 1. Deadlock in buffer recycling — `driver/fthd_v4l2.c`

**Upstream behavior:** `buf_queue()` calls `fthd_channel_wait_ready()`,
which can block for up to 2 seconds while the vb2 queue lock is held.
This prevents `DQBUF` from running, starves the buffer pipeline, and
freezes the stream after the first frame.

**Fix:** `buf_queue()` now marks the buffer as `BUF_DRV_QUEUED` and
schedules a workqueue (`buf_work`) to perform the actual hardware
submission. The workqueue runs *without* the queue lock and may
safely block on the ISP firmware acknowledgment, while `DQBUF`
proceeds concurrently and keeps the pipeline flowing.

### 2. Missing timestamps and sequence numbers — `driver/fthd_v4l2.c`

**Upstream behavior:** the driver advertises
`V4L2_BUF_FLAG_TIMESTAMP_MONOTONIC` but never sets buffer timestamps
or sequence counters. Modern V4L2 consumers (GStreamer, PipeWire,
GNOME Camera, Cheese) see all-zero timestamps and decide the stream
is stalled.

**Fix:** the dequeue path now stamps each buffer with `ktime_get_ns()`
and increments a per-stream sequence counter.

### 3. Variable shadowing in IRQ handler — `driver/fthd_drv.c`

**Upstream behavior:** `fthd_irq_work()` reuses the variable `i` for
both its outer `while` loop and an inner `for` loop. The inner loop
clobbers the outer counter, breaking the safety bound.

**Fix:** the inner loop now uses `j` as its counter so the outer
loop's safety check works as intended.

### Supporting changes

- `driver/fthd_drv.h` — added `buf_work` (workqueue) and `sequence`
  counter fields to `struct fthd_private`.
- `driver/fthd_buffer.h` — added `fthd_send_h2t_buffer()` declaration
  so the workqueue in `fthd_v4l2.c` can submit buffers to hardware.
- `driver/fthd_drv.c` — added `buf_work` cleanup on remove.

## What is unchanged

Every other file in `driver/` and all of `firmware-extractor/` is a
verbatim copy of the upstream sources at the time this repository was
created. They retain their original copyright notices and license
headers.

## Related upstream issues

- [patjak/facetimehd#315](https://github.com/patjak/facetimehd/issues/315)
  — Frozen image on kernels 6.15+
- [patjak/facetimehd#303](https://github.com/patjak/facetimehd/issues/303)
  — Build fixes for kernel 6.13+
