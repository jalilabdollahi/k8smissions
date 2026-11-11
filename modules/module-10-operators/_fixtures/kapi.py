"""kapi: tiny Kubernetes API helper for controller scripts (stdlib only).

Mounted from ConfigMap `kapi-lib` at /kapi (PYTHONPATH=/kapi). Usage:
    from kapi import api, NS, log, forever
    code, obj = api("GET", "/apis/acme.io/v1/namespaces/%s/widgets" % NS)
"""
import json, ssl, time, urllib.request, urllib.error

SA = "/var/run/secrets/kubernetes.io/serviceaccount/"
NS = open(SA + "namespace").read().strip()
_CTX = ssl.create_default_context(cafile=SA + "ca.crt")


def api(method, path, body=None, ctype="application/json"):
    """Call the API server. Returns (status, parsed JSON or {}); never raises on HTTP errors."""
    req = urllib.request.Request("https://kubernetes.default.svc" + path, method=method,
                                 data=None if body is None else json.dumps(body).encode())
    req.add_header("Authorization", "Bearer " + open(SA + "token").read().strip())
    req.add_header("Content-Type", ctype)
    req.add_header("Accept", "application/json")
    try:
        with urllib.request.urlopen(req, context=_CTX, timeout=15) as r:
            return r.status, json.loads(r.read() or b"{}")
    except urllib.error.HTTPError as e:
        raw = e.read()
        try:
            return e.code, json.loads(raw or b"{}")
        except ValueError:
            return e.code, {"message": raw.decode(errors="replace")}
    except Exception as e:  # connection problems: report like a 5xx so loops carry on
        return 599, {"message": str(e)}


def patch(path, body):
    return api("PATCH", path, body, "application/merge-patch+json")


def log(*parts):
    print(time.strftime("%H:%M:%S"), *parts, flush=True)


def forever(fn, every=2):
    """Run fn() every `every` seconds; an exception is logged, never fatal."""
    while True:
        try:
            fn()
        except Exception as e:
            log("pass failed:", repr(e))
        time.sleep(every)
