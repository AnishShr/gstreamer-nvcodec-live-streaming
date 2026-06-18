#!/bin/bash
set -euo pipefail

# Ubuntu 22.04 ships GStreamer 1.20, whose gstreamer1.0-plugins-bad package
# already includes the NVIDIA encoder via the nvcodec plugin. No source build
# needed — just install the packages and verify.

sudo apt update
sudo apt install -y \
    gstreamer1.0-tools \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav

# Clear the GStreamer plugin cache — a stale cache can hide newly-installed
# plugins or mask plugins that failed to load after a driver/CUDA upgrade.
rm -rf ~/.cache/gstreamer-1.0/

# Verify the nvcodec plugin loads and its CUDA dependencies resolve.
gst-inspect-1.0 nvcodec
ldd /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstnvcodec.so | grep -iE "cuda|nvcuvid|not found" || true

if ! gst-inspect-1.0 nvh264enc > /dev/null 2>&1; then
    echo "nvh264enc not found after install." >&2
    echo "Check that the NVIDIA driver is loaded (nvidia-smi) and that" >&2
    echo "CUDA is installed at /usr/local/cuda." >&2
    exit 1
fi

gst-inspect-1.0 nvh264enc
