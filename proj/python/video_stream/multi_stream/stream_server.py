from imutils.video import VideoStream
from flask import Response
from flask import Flask
from flask import render_template

import threading
import argparse
import datetime
import imutils
import time
import cv2

outputFrame = None
lock = threading.Lock()

app = Flask(__name__)

vs = VideoStream(resolution=(240, 180), src = 0).start()
time.sleep(2.0)

@app.route("/")
def index():
	return render_template("index.html")

def get_frame(frameCount):
	global vs, outputFrame, lock
	total = 0

	while True:
		frame = vs.read()
		#frame = imutils.resize(frame, width=320)
		total += 1

		with lock:
			outputFrame = frame.copy()

def generate():
	global outputFrame, lock

	while True:
		with lock:
			if outputFrame is None:
				continue

			(flag, encodedImage) = cv2.imencode(".jpg", outputFrame)

			if not flag:
				continue

		yield(b'--frame\r\n' b'Content-Type: image/jpeg\r\n\r\n' + bytearray(encodedImage) + b'\r\n')

@app.route('/video_feed')
def video_feed():
	return Response(generate(), mimetype = "multipart/x-mixed-replace; boundary=frame")

if __name__ == '__main__':
	t = threading.Thread(target=get_frame, args=(32,))
	t.daemon = True
	t.start()

	app.run(host="0.0.0.0", port=33333, threaded=True, use_reloader=False)

vs.stop()
