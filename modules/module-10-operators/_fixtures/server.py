"""Webhook server fixture: HTTPS on 8443 for AdmissionReview and ConversionReview (stdlib only).

Mounted from ConfigMap `webhook-server` at /app. TLS files come from a Secret at /tls
(tls.crt, tls.key) and are loaded ONCE at start. The behaviour comes from a handler
module mounted at /handler/handler.py (override with HANDLER=/path/file.py) defining any of:
    validate(request)  -> (allowed: bool, message: str)
    mutate(request)    -> (allowed: bool, message: str, patch: list of JSON-patch ops)
    convert(objects, desiredAPIVersion) -> list of converted objects (raise ValueError to fail)
Routes: POST /validate, /mutate, /convert. GET /healthz answers ok.
"""
import base64, importlib.util, json, os, ssl, sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

path = os.environ.get("HANDLER", "/handler/handler.py")
spec = importlib.util.spec_from_file_location("handler", path)
H = importlib.util.module_from_spec(spec)
spec.loader.exec_module(H)


def say(*a):
    print(*a, flush=True)


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *a):
        pass

    def reply(self, code, obj):
        raw = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    def do_GET(self):
        self.reply(200, {"status": "ok"})

    def do_POST(self):
        review = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))) or b"{}")
        route = self.path.split("?")[0]
        api_version, kind = review.get("apiVersion", ""), review.get("kind", "")
        try:
            if route in ("/validate", "/mutate"):
                req = review["request"]
                res = {"uid": req["uid"], "allowed": True}
                if route == "/validate":
                    ok, msg = H.validate(req)
                    patch = None
                else:
                    ok, msg, patch = H.mutate(req)
                res["allowed"] = bool(ok)
                if not ok:
                    res["status"] = {"code": 403, "message": msg}
                elif patch:
                    res["patchType"] = "JSONPatch"
                    res["patch"] = base64.b64encode(json.dumps(patch).encode()).decode()
                obj = req.get("object") or req.get("oldObject") or {}
                say("%s %s %s/%s -> %s %s" % (route, req.get("operation"), req.get("namespace", ""),
                    (obj.get("metadata") or {}).get("name") or req.get("name", ""), "allow" if ok else "DENY", msg or ""))
                return self.reply(200, {"apiVersion": api_version, "kind": kind, "response": res})
            if route == "/convert":
                req = review["request"]
                res = {"uid": req["uid"]}
                try:
                    res["convertedObjects"] = H.convert(req["objects"], req["desiredAPIVersion"])
                    res["result"] = {"status": "Success"}
                except ValueError as e:
                    res["convertedObjects"] = []
                    res["result"] = {"status": "Failed", "message": str(e)}
                say("/convert %d object(s) -> %s: %s" % (len(req["objects"]), req["desiredAPIVersion"], res["result"]["status"]))
                return self.reply(200, {"apiVersion": api_version, "kind": kind, "response": res})
            say("404 no route", self.path)
            self.reply(404, {"message": "no route " + route})
        except Exception as e:
            say("handler error:", repr(e))
            self.reply(500, {"message": repr(e)})


ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
ctx.load_cert_chain("/tls/tls.crt", "/tls/tls.key")
srv = ThreadingHTTPServer(("0.0.0.0", 8443), Handler)
srv.socket = ctx.wrap_socket(srv.socket, server_side=True)
say("webhook server listening on :8443 with handler", path)
srv.serve_forever()
