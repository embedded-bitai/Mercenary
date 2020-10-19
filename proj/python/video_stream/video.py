from imutils.video import VideoStream

import numpy as np
import imutils
import cv2

vs = VideoStream(src = 0).start()
while True:
	frame = vs.read()

	cv2.imshow('frame', frame)
	if cv2.waitKey(1) & 0xFF == ord('q'):
		break

vs.stop()
