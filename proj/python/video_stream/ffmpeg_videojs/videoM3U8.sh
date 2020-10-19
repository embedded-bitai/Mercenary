#!/bin/bash

python -m http.server 33333 &

ffmpeg -i /dev/video0 -level 3.0 -s 640x480 -start_number 0 -hls_time 10 -hls_list_size 10 -f hls index.m3u8 &
