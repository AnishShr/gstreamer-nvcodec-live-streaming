#!/bin/bash
gst-launch-1.0 udpsrc port=5000 \
    caps="application/x-rtp,media=video,clock-rate=90000,encoding-name=H264,payload=96" \
    ! rtpjitterbuffer latency=400 do-lost=true \
    ! rtph264depay ! h264parse ! avdec_h264 ! videoconvert ! autovideosink sync=false