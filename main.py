from flask import Flask, send_from_directory, jsonify, request, send_file, Response

app = Flask(__name__)

@app.route('/src/<path:filepath>')
def src_file(filepath):
    return send_from_directory('src', filepath)

@app.route('/')
def index():
    with open("./src/main.lua", "r") as f:
        c = f.read().strip()
    c = c.replace("https://raw.githubusercontent.com/ImLangNaoCoBe/onepiece-final-FS/refs/heads/main/src/",
                  'http://192.168.2.115:5000/src/')
    return c

app.run('0.0.0.0', 5000, debug=True)