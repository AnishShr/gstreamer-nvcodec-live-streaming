#!/bin/bash
gst-launch-1.0 ximagesrc xid=$1 use-damage=false \
    ! videoconvert ! video/x-raw,format=NV12 \
    ! nvh264enc preset=p4 tune=ultra-low-latency rc-mode=vbr bitrate=3000 max-bitrate=5000 gop-size=30 \
    ! h264parse config-interval=-1 \
    ! rtph264pay pt=96 config-interval=-1 mtu=1200 \
    ! udpsink host=10.0.1.2 port=5000 sync=false