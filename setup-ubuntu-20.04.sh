#!/bin/bash
set -euo pipefail

# Installs GStreamer + builds the nvh264enc plugin against CUDA 11.x on Ubuntu 20.04.
# See gstreamer-nvenc-setup.md for background.

sudo apt update
sudo apt install -y \
    gstreamer1.0-tools \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    meson ninja-build \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    git

BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

git clone --depth 1 --branch 1.16.3 \
    https://gitlab.freedesktop.org/gstreamer/gst-plugins-bad.git \
    "$BUILD_DIR/gst-plugins-bad"

cd "$BUILD_DIR/gst-plugins-bad"

cat > sys/nvenc/meson.build << 'PATCH'
nvenc_sources = [
  'gstnvbaseenc.c',
  'gstnvenc.c',
  'gstnvh264enc.c',
  'gstnvh265enc.c',
]

use_nvenc_gl = false
extra_c_args = []

nvenc_option = get_option('nvenc')
if nvenc_option.disabled()
  subdir_done()
endif

gstnvenc = library('gstnvenc',
  nvenc_sources,
  c_args : gst_plugins_bad_args + extra_c_args,
  include_directories : [configinc],
  dependencies : [gstbase_dep, gstvideo_dep, gstpbutils_dep, cuda_dep, cudart_dep, gmodule_dep],
  install : true,
  install_dir : plugins_install_dir,
)
pkgconfig.generate(gstnvenc, install_dir : plugins_pkgconfig_install_dir)
PATCH

CUDA_PATH=/usr/local/cuda meson build -Dauto_features=disabled -Dnvenc=enabled
ninja -C build

sudo cp build/sys/nvenc/libgstnvenc.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/

gst-inspect-1.0 nvh264enc
