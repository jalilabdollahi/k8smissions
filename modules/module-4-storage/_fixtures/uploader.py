# Tiny upload service used by the storage levels (stdlib only).
#   POST /upload/<name>   stores the request body as DATA_DIR/<name>
#   GET  /files/<name>    returns the stored body (404 if missing)
#   GET  /status          JSON: data_dir, number of stored files
import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

DATA = os.environ.get("DATA_DIR", "/data")
PORT = int(os.environ.get("PORT", "8080"))
os.makedirs(DATA, exist_ok=True)


class Handler(BaseHTTPRequestHandler):
    def _send(self, code, body, ctype="text/plain"):
        raw = body if isinstance(body, bytes) else body.encode()
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    def do_GET(self):
        if self.path == "/status":
            names = sorted(os.listdir(DATA)) if os.path.isdir(DATA) else []
            return self._send(200, json.dumps({"data_dir": DATA, "files": len(names)}), "application/json")
        if self.path.startswith("/files/"):
            path = os.path.join(DATA, os.path.basename(self.path))
            if os.path.isfile(path):
                with open(path, "rb") as f:
                    return self._send(200, f.read())
            return self._send(404, "not found\n")
        self._send(404, "unknown path\n")

    def do_POST(self):
        if not self.path.startswith("/upload/"):
            return self._send(404, "unknown path\n")
        size = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(size)
        with open(os.path.join(DATA, os.path.basename(self.path)), "wb") as f:
            f.write(body)
        self._send(201, "stored\n")

    def log_message(self, fmt, *args):
        print("%s %s" % (self.command, self.path), flush=True)


print("uploader listening on %d, storing in %s" % (PORT, DATA), flush=True)
ThreadingHTTPServer(("", PORT), Handler).serve_forever()
