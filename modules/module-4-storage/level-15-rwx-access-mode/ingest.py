# ingest service used by the level; version comes from INGEST_VERSION.
#   v1 writes the first batch file to /data; v2 also needs a spool directory at /spool.
#   GET anything -> "version=<n> data=<ok|missing> spool=<ok|missing|n/a>"
import os
import time
from http.server import BaseHTTPRequestHandler, HTTPServer

VERSION = os.environ.get("INGEST_VERSION", "1")
FIRST = "/data/first-batch.dat"

if VERSION == "1" and not os.path.exists(FIRST):
    with open(FIRST, "w") as f:
        f.write("batch-0001 records=48213 sealed\n")
with open("/data/starts.log", "a") as f:
    f.write("v%s started %d\n" % (VERSION, time.time()))


def status():
    data = "ok" if os.path.exists(FIRST) else "missing"
    spool = "n/a"
    if VERSION != "1":
        try:
            probe = "/spool/.probe-%d" % os.getpid()
            with open(probe, "w") as f:
                f.write("x")
            os.remove(probe)
            spool = "ok" if os.path.ismount("/spool") else "missing"
        except OSError:
            spool = "missing"
    return "version=%s data=%s spool=%s\n" % (VERSION, data, spool)


class H(BaseHTTPRequestHandler):
    def do_GET(self):
        raw = status().encode()
        self.send_response(200)
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    def log_message(self, *a):
        pass


print("ingest v%s up" % VERSION, flush=True)
HTTPServer(("", 8080), H).serve_forever()
