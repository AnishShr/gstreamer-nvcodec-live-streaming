#!/bin/bash
# SRT sender. Same encoder config as sender_teleop_match.sh, but the transport
# is SRT instead of plain RTP/UDP. SRT adds automatic retransmission (ARQ) of
# lost packets within a bounded latency window -- this is the main reason
# remote-teleop (WebRTC NACK) looks artifact-free and plain udpsink does not.
#
# Topology: this sender is the SRT "caller" and connects to the receiver
# (the listener) at 10.0.1.2:5000. Start the receiver first.
#
# latency=200 (ms) is the retransmission window. Bigger = more loss recovery
# but more end-to-end delay; smaller = lower delay but less headroom to
# retransmit. Rule of thumb: latency >= 3-4 x RTT. Both peers negotiate max().
#
# Requires the GStreamer 'srt' plugin (libsrt) and mpegtsmux on THIS machine:
#   sudo apt install gstreamer1.0-plugins-bad   # then: gst-inspect-1.0 srtsink

gst-launch-1.0 ximagesrc xid=$1 use-damage=false \
    ! videoconvert ! video/x-raw,format=NV12 \
    ! nvh264enc preset=low-latency-hq rc-mode=cbr bitrate=6000 gop-size=30 bframes=0 \
    ! video/x-h264,profile=high \
    ! h264parse config-interval=-1 \
    ! mpegtsmux alignment=7 \
    ! srtsink uri="srt://10.0.1.2:5000?mode=caller&latency=200" sync=false
