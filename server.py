from flask import Flask, request

app = Flask(__name__)

@app.route('/upload', methods=['POST'])
def upload_file():
    file = request.files['file']
    file.save(f"/data/data/com.termux/files/home/{file.filename}")  # Save file in Termux home directory
    return "File received successfully!", 200
@app.route('/out', methods = ['GET'])
def out_data():
    return "OK", 200
if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)

