from flask import send_file
from flask import Flask, request
from werkzeug.utils import secure_filename

import os
import socket

#import requests
#
#url = "http://localhost:5000/save"
#
#headers = {
#    "Content-Type": "audio/wav",
#}
#params = {"uploadType": "media", "name": "test.wav"}
#with open('test.wav', 'rb') as file:
#  r = requests.post(url, params=params, headers=headers, data=file)
#print(r.text)

app = Flask(__name__)

# RFC - https://tools.ietf.org/html/rfc3003
@app.route('/mp3_download')
def mp3_download():
    file_name = "./TwoStepDR_320kbps.mp3"
    return send_file(file_name,
                     mimetype='audio/mpeg',
                     attachment_filename='mp3_test.mp3',# 다운받아지는 파일 이름. 
                     as_attachment=True)

@app.route("/file_download")
def hello():
    return '''
    <a href="/mp3_download">Click me.</a>
    
    <form method="get" action="mp3_download">
        <button type="submit">Download!</button>
    </form>
    '''

@app.route("/upload")
def upload():
	#<form action="http://localhost:5000/file_upload" method="POST"
	return '''
	<form action="/upload_test" method="POST"
			enctype="multipart/form-data">
		<input type="file" name="audio_data"/>
		<input type="submit"/>
	</form>
	'''

#@app.route("/file_upload")
#def file_upload():
#	if request.method == 'POST':
#		f = request.files['file']
#		print(f.filename)
#		f.save(secure_filename(f.filename))
#		return 'uploads dir -> file upload success'

@app.route("/upload_test", methods=['POST', 'GET'])
def upload_test():
	if request.method == "POST":
		f = request.files['audio_data']
		print(f.filename)
		print(f)

		(host, port) = ('localhost', 37373)
		s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
		s.connect((host, port))

		with open(f.filename, 'rb') as wave_file:
			for l in f:
				s.sendall(l)

		s.close()

		#with open('audio.wav', 'wb') as audio:
		#	f.save(audio)
		print('file upload Success')

#@app.route("/upload_test", methods=['POST', 'GET'])
#def index():
#    if request.method == "POST":
#        f = request.files['audio_data']
#		with open('audio.wav', 'wb') as audio:
#            f.save(audio)
#        print('file uploaded successfully')
#    else:
#        print('file uploaded failure')

if __name__ == '__main__':
	app.run(debug=True)
