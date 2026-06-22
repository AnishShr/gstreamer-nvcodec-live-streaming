#!/bin/bash
gst-launch-1.0 udpsrc port=5000 buffer-size=8388608 \
    caps="application/x-rtp,media=video,clock-rate=90000,encoding-name=H264,payload=96" \
    ! rtpstorage size-time=220000000 \
    ! rtpssrcdemux \
    ! application/x-rtp,media=video,clock-rate=90000,encoding-name=H264,payload=96 \
    ! rtpjitterbuffer do-lost=true latency=200 \
    ! rtpulpfecdec pt=122 \
    ! rtph264depay ! h264parse ! avdec_h264 ! videoconvert ! autovideosink sync=false