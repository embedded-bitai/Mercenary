from flask import send_file
from flask import Flask

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

if __name__ == '__main__':
	app.run(debug=True)
