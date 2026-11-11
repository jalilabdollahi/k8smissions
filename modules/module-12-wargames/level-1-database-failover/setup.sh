#!/bin/bash
# Pre-incident state: ledger-db is healthy and holds a booked entry. Then the drill happens:
# the node that holds the data volume is cordoned and the db pod is deleted.
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh

kubectl -n "$NS" apply -f - <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: ledger-db-src
data:
  db.py: |
    import json, os, sys, threading
    from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
    PATH = "/data/store.json"
    LOCK = threading.Lock()
    def load():
        try:
            return json.load(open(PATH))
        except Exception:
            return {}
    class H(BaseHTTPRequestHandler):
        def log_message(self, *a): pass
        def reply(self, code, body):
            b = body.encode()
            self.send_response(code); self.send_header("Content-Length", str(len(b))); self.end_headers(); self.wfile.write(b)
        def do_GET(self):
            if self.path == "/healthz": return self.reply(200, "ok")
            if self.path.startswith("/kv/"):
                v = load().get(self.path[4:])
                return self.reply(200, v) if v is not None else self.reply(404, "not found")
            self.reply(404, "no such path")
        def do_PUT(self):
            n = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(n).decode()
            with LOCK:
                d = load(); d[self.path[4:]] = body
                tmp = PATH + ".tmp"
                with open(tmp, "w") as f:
                    json.dump(d, f); f.flush(); os.fsync(f.fileno())
                os.replace(tmp, PATH)
            self.reply(201, "stored")
    ThreadingHTTPServer(("0.0.0.0", 5000), H).serve_forever()
---
apiVersion: v1
kind: Service
metadata:
  name: ledger-db-peers
spec:
  clusterIP: None
  selector: {app: ledger-db}
  ports:
  - {name: sql, port: 5000}
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: ledger-db
spec:
  serviceName: ledger-db-peers
  replicas: 1
  selector:
    matchLabels: {app: ledger-db}
  template:
    metadata:
      labels: {app: ledger-db}
    spec:
      terminationGracePeriodSeconds: 2
      containers:
      - name: db
        image: python:3.12-alpine
        command: ["python", "-u", "/src/db.py"]
        ports:
        - {containerPort: 5000}
        readinessProbe:
          httpGet: {path: /healthz, port: 5000}
          periodSeconds: 3
        volumeMounts:
        - {name: data, mountPath: /data}
        - {name: src, mountPath: /src}
      volumes:
      - name: src
        configMap: {name: ledger-db-src}
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests: {storage: 100Mi}
YAML
kubectl -n "$NS" rollout status sts/ledger-db --timeout=150s || exit 1

kubectl -n "$NS" exec ledger-db-0 -- python -c '
import urllib.request
r = urllib.request.Request("http://127.0.0.1:5000/kv/entry-0001", data=b"{\"account\":\"ACME-4417\",\"amount\":1250.00}", method="PUT")
print(urllib.request.urlopen(r).status)' || exit 1

node=$(kubectl -n "$NS" get pod ledger-db-0 -o jsonpath='{.spec.nodeName}')
kubectl cordon "$node" >/dev/null
kubectl -n "$NS" delete pod ledger-db-0 --wait=false >/dev/null
