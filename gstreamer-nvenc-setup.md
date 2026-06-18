# Installing GStreamer nvh264enc on Ubuntu 20.04 with CUDA 11.x

Ubuntu 20.04's `gstreamer1.0-plugins-bad` package (GStreamer 1.16) does not include the NVIDIA hardware encoder plugin (`nvh264enc`). The build system also only searches for CUDA up to version 10.1. This guide builds the `nvenc` plugin from source against your existing CUDA installation.

## Prerequisites

- Ubuntu 20.04
- NVIDIA GPU with NVENC support (GTX 600+ / Quadro K series+)
- NVIDIA driver installed
- CUDA toolkit installed at `/usr/local/cuda`

## Steps

```bash
# 1. Install GStreamer plugins and build dependencies
sudo apt install \
    gstreamer1.0-tools \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    meson ninja-build \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev

# 2. Clone matching GStreamer source (1.16.3 matches Ubuntu 20.04)
git clone --depth 1 --branch 1.16.3 \
    https://gitlab.freedesktop.org/gstreamer/gst-plugins-bad.git
cd gst-plugins-bad

# 3. Patch nvenc meson.build to skip GL interop
#    (avoids needing libgstreamer-gl1.0-dev which has no Ubuntu 20.04 package)
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

# 4. Configure (CUDA_PATH tells meson where to find CUDA 11.x)
CUDA_PATH=/usr/local/cuda meson build -Dauto_features=disabled -Dnvenc=enabled

# 5. Build
ninja -C build

# 6. Install the plugin
sudo cp build/sys/nvenc/libgstnvenc.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/

# 7. Verify
gst-inspect-1.0 nvh264enc
```

## Usage note

GStreamer 1.16's `nvh264enc` has different property values than newer versions. Use `rc-mode=cbr` instead of `cbr-ld-hq`:

```bash
gst-launch-1.0 ximagesrc xid=0x460000a use-damage=false \
    ! videoconvert ! video/x-raw,format=NV12 \
    ! nvh264enc preset=low-latency-hq rc-mode=cbr bitrate=6000 gop-size=30 \
    ! h264parse config-interval=-1 \
    ! rtph264pay pt=96 config-interval=-1 mtu=1200 \
    ! udpsink host=172.17.155.131 port=5000 sync=false
```

## Cleanup (optional)

```bash
cd .. && rm -rf gst-plugins-bad
```
