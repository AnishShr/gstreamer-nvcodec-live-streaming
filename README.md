# gstreamer-nvcodec-live-streaming

Low-latency H.264 screen streaming over RTP/UDP using GStreamer with NVIDIA's
hardware encoder (`nvh264enc`).

## Files

- `setup-ubuntu-20.04.sh` — installs GStreamer and builds the `nvh264enc`
  plugin from source. Ubuntu 20.04's `gstreamer1.0-plugins-bad` (1.16) ships
  without the NVIDIA encoder and its build system only looks for CUDA up to
  10.1, so the plugin has to be compiled against the local CUDA 11.x install.
- `setup-ubuntu-22.04.sh` — installs the GStreamer apt packages and verifies
  `nvh264enc` is registered. On 22.04 the stock `gstreamer1.0-plugins-bad`
  (1.20) already includes the NVIDIA encoder via the `nvcodec` plugin, so no
  source build is needed.
- `sender.sh` — captures an X11 window with `ximagesrc`, encodes with
  `nvh264enc`, and sends RTP/H.264 over UDP.
- `receiver.sh` — receives the RTP stream, decodes with `avdec_h264`, and
  displays it.

## Quick start

On the sender machine (with NVIDIA GPU), run the script for your Ubuntu
version once:

```bash
./setup-ubuntu-20.04.sh   # or ./setup-ubuntu-22.04.sh
```

Then edit `sender.sh` (see Configuration below) and run it:

```bash
./sender.sh
```

On the receiver machine:

```bash
./receiver.sh
```

## Configuration

`sender.sh` hard-codes values you will need to change:

- `xid=` — the X11 window ID to capture. Find it with `xwininfo`.
- `host=` — the receiver's IP address.
- `port=` — defaults to 5000; must match `receiver.sh`.

## Requirements

- Ubuntu 20.04 or 22.04
- NVIDIA GPU with NVENC support (GTX 600+ / Quadro K series+)
- NVIDIA driver and CUDA toolkit at `/usr/local/cuda`
