from pathlib import Path

from flask import Flask, Response

app = Flask(__name__)
artifact = Path(__file__).resolve().parent / "dist" / "redliner.lua"

@app.route('/')
def index():
    try:
        content = artifact.read_bytes()
    except FileNotFoundError:
        return Response("Build dist/redliner.lua before starting the server.\n", status=503,
                        content_type="text/plain; charset=utf-8")
    return Response(content, content_type="text/plain; charset=utf-8")

if __name__ == "__main__":
    app.run('0.0.0.0', 5000)
