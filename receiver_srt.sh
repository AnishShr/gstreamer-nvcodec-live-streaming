#!/bin/bash
# SRT receiver, pairs with sender_srt.sh. This end is the SRT "listener":
# it binds port 5000 and waits for the sender (caller) to connect.
# Start this BEFORE the sender.
#
# latency=200 must be >= a sensible retransmit window; SRT negotiates the
# max() of both peers, so keep it consistent with the sender.
#
# Requires the GStreamer 'srt' plugin (libsrt) and tsdemux on THIS machine:
#   sudo apt install gstreamer1.0-plugins-bad   # then: gst-inspect-1.0 srtsrc

gst-launch-1.0 srtsrc uri="srt://0.0.0.0:5000?mode=listener&latency=200" \
    ! tsdemux ! h264parse ! avdec_h264 ! videoconvert ! autovideosink sync=false
