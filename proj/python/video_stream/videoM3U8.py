from imutils.video import VideoStream
from ffmpeg_streaming import Formats

import ffmpeg_streaming
import numpy as np
import imutils
import cv2

video = ffmpeg_streaming.input('/dev/video0', capture=True)

hls = video.hls(Formats.h264())
hls.auto_generate_representations()
hls.output('/home/oem/proj/PythonVideoStream/media/hls.m3u8')
