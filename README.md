# gstreamer-nvcodec-live-streaming

Low-latency H.264 screen streaming over UDP using NVIDIA's hardware encoder
(`nvh264enc` / `h264_nvenc`). Most scripts use GStreamer with RTP; one
sender/receiver pair uses ffmpeg with MPEG-TS instead.

## Files

### Setup

- `setup-ubuntu-20.04.sh` — installs GStreamer and builds the `nvh264enc`
  plugin from source. Ubuntu 20.04's `gstreamer1.0-plugins-bad` (1.16) ships
  without the NVIDIA encoder and its build system only looks for CUDA up to
  10.1, so the plugin has to be compiled against the local CUDA 11.x install.
- `setup-ubuntu-22.04.sh` — installs the GStreamer apt packages and verifies
  `nvh264enc` is registered. On 22.04 the stock `gstreamer1.0-plugins-bad`
  (1.20) already includes the NVIDIA encoder via the `nvcodec` plugin, so no
  source build is needed.

### GStreamer / RTP family

These senders emit RTP/H.264 (`rtph264pay`); use them with a GStreamer
RTP receiver.

- `sender.sh` — captures a single X11 window (`ximagesrc xid=…`), encodes with
  `nvh264enc`, sends RTP/H.264 over UDP.
- `sender_better.sh` — same as `sender.sh` plus ULP forward error correction
  (`rtpulpfecenc`, `multipacket=true`). **Pair with `receiver_better.sh`**,
  whose `rtpulpfecdec` recovers lost packets from the FEC stream (`pt=122`).
- `sender_fullscreen1.sh` — captures the whole screen (no `xid`), `nvh264enc`
  with `zerolatency=true`.
- `sender_fullscreen2.sh` — captures the whole screen using the newer
  `nvcudah264enc` element (`preset=p4 tune=ultra-low-latency`).
- `receiver.sh` — receives RTP, decodes with `avdec_h264`, displays it.
- `receiver_better.sh` — loss-resilient receiver: larger jitter buffer plus
  FEC decode (`rtpulpfecdec`). Pairs with `sender_better.sh`.

### ffmpeg / MPEG-TS family

- `sender_ffmpeg_vlc.sh` — ffmpeg alternative: captures with `x11grab`,
  encodes with `h264_nvenc`, sends raw **MPEG-TS** over UDP (not RTP).
- `receiver_ffmpeg_vlc.sh` — plays the MPEG-TS stream with VLC
  (`udp://@:5000`).

## Pairing

Senders and receivers must share the same transport. They are **not**
interchangeable across families:

| Sender | Transport | Use with receiver |
| --- | --- | --- |
| `sender.sh`, `sender_fullscreen1.sh`, `sender_fullscreen2.sh` | RTP | `receiver.sh` |
| `sender_better.sh` | RTP + ULP-FEC | `receiver_better.sh` |
| `sender_ffmpeg_vlc.sh` | MPEG-TS | `receiver_ffmpeg_vlc.sh` |

A GStreamer RTP receiver cannot read the ffmpeg MPEG-TS stream, and VLC's
`udp://@:5000` expects MPEG-TS, not RTP.

## Quick start

On the sender machine (with NVIDIA GPU), run the script for your Ubuntu
version once:

```bash
./setup-ubuntu-20.04.sh   # or ./setup-ubuntu-22.04.sh
```

Then edit a sender (see Configuration below) and run it, e.g.:

```bash
./sender.sh
```

On the receiver machine, run the matching receiver from the table above:

```bash
./receiver.sh
```

## Configuration

The senders hard-code values you will need to change:

- `xid=` — the X11 window ID to capture (`sender.sh`, `sender_better.sh`).
  Find it with `xwininfo`. The `*_fullscreen*` senders capture the whole
  screen and have no `xid`.
- `host=` (GStreamer) / `udp://…` (ffmpeg) — the receiver's IP address,
  `10.0.1.2` by default everywhere.
- `port=` — defaults to 5000; must match the receiver.

## Requirements

- Ubuntu 20.04 or 22.04
- NVIDIA GPU with NVENC support (GTX 600+ / Quadro K series+)
- NVIDIA driver and CUDA toolkit at `/usr/local/cuda`
- ffmpeg + VLC (only for the `*_ffmpeg_vlc.sh` pair)

> **ffmpeg note:** `sender_ffmpeg_vlc.sh` uses `-preset llhq -rc cbr`, which
> works on both Ubuntu 20.04 (ffmpeg 4.2) and 22.04 (ffmpeg 4.4+). The modern
> `-preset p1..p7` / `-tune` options are **not** available in 20.04's ffmpeg,
> so the legacy `llhq` preset is used deliberately.
