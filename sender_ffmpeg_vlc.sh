#!/bin/bash
ffmpeg -f x11grab -framerate 30 -i :0.0 -c:v h264_nvenc -preset llhq -rc cbr -zerolatency 1 -b:v 6000k -maxrate 6000k -bufsize 3000k -g 30 -bf 0 -pix_fmt yuv420p -f mpegts "udp://10.0.1.2:5000?pkt_size=1316"
