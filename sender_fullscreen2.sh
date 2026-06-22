#!/bin/bash
gst-launch-1.0 ximagesrc use-damage=false ! videoconvert ! video/x-raw,format=NV12 ! nvcudah264enc preset=p4 tune=ultra-low-latency rc-mode=cbr bitrate=6000 gop-size=30 ! h264parse config-interval=-1 ! rtph264pay pt=96 config-interval=-1 mtu=1200 ! udpsink host=10.0.1.2 port=5000 sync=false
