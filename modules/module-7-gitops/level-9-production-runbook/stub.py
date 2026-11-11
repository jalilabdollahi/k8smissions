import json
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

state = {"version": 2, "applied": []}
lock = threading.Lock()


class Handler(BaseHTTPRequestHandler):
    def reply(self, code, body):
        data = body.encode()
        self.send_response(code)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path == "/version":
            self.reply(200, str(state["version"]))
        elif self.path == "/status":
            self.reply(200, json.dumps(state))
        else:
            self.reply(404, "not found")

    def do_POST(self):
        if not self.path.startswith("/migrate/"):
            return self.reply(404, "not found")
        try:
            target = int(self.path.rsplit("/", 1)[1])
        except ValueError:
            return self.reply(400, "bad version")
        with lock:
            if target <= state["version"]:
                return self.reply(409, "already at version %d" % state["version"])
            state["version"] = target
            state["applied"].append(target)
        self.reply(200, "migrated to %d" % target)

    def log_message(self, *args):
        pass


ThreadingHTTPServer(("", 8080), Handler).serve_forever()
