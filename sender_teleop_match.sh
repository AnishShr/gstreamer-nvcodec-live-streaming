#!/bin/bash
# Encoder parameters matched as closely as nvh264enc allows to the
# remote-teleop NvMedia config (src/video_encoder.cpp):
#   - H.264 High profile, CBR, 1 ref frame, 0 B-frames, repeat SPS/PPS on IDR.
#
# Deliberate DEVIATIONS from remote-teleop, and why:
#   - GOP: remote-teleop uses fps*10 (300 frames / 10 s) but relies on WebRTC
#     PLI to force an IDR the moment the decoder reports loss. This udpsink
#     pipeline has NO feedback channel, so a long GOP means artifacts persist
#     until the next scheduled keyframe. Keep it SHORT here (1 s).
#   - Profile/level: forced to high; level left to the encoder (4.2 in
#     remote-teleop fits its teleop resolution; full desktop may exceed it).
#
# NOTE: verify property names/units on the SENDER machine with:
#   gst-inspect-1.0 nvh264enc
# (nvh264enc is not installed on this receiver machine.)

gst-launch-1.0 ximagesrc xid=$1 use-damage=false \
    ! videoconvert ! video/x-raw,format=NV12 \
    ! nvh264enc preset=low-latency-hq rc-mode=cbr bitrate=6000 gop-size=30 bframes=0 \
    ! video/x-h264,profile=high \
    ! h264parse config-interval=-1 \
    ! rtph264pay pt=96 config-interval=-1 mtu=1200 \
    ! udpsink host=10.0.1.2 port=5000 sync=false
