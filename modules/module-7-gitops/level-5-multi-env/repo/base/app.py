import http.server, json, os

class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/config":
            body = json.dumps({"log_level": os.environ.get("LOG_LEVEL", "unset"), "pod": os.environ.get("HOSTNAME", "")}).encode()
        else:
            body = b"shop ok"
        self.send_response(200)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *a):
        pass

http.server.ThreadingHTTPServer(("", 8080), H).serve_forever()
