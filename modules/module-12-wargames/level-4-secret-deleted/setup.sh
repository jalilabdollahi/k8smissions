#!/bin/bash
# Before the incident: billing-api (3 pods) talks to billing-db with the password in db-credentials.
# Then the half-finished rotation: the Secret is deleted and a new rollout is started.
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
PW=$(LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | head -c 18)

kubectl -n "$NS" apply -f - <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: billing-db-engine
type: Opaque
stringData:
  admin-password: "$PW"
---
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
type: Opaque
stringData:
  username: billing
  password: "$PW"
  DB_PASS: "$PW"
YAML

kubectl -n "$NS" apply -f - <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: billing-src
data:
  db.py: |
    import os
    from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
    PW = os.environ["DB_ADMIN_PASSWORD"]
    STORE = {}
    class H(BaseHTTPRequestHandler):
        def log_message(self, fmt, *a): print(self.command, self.path, flush=True)
        def reply(self, code, body):
            b = body.encode()
            self.send_response(code); self.send_header("Content-Length", str(len(b))); self.end_headers(); self.wfile.write(b)
        def authed(self):
            if self.headers.get("X-DB-Password") != PW:
                print("rejected: bad password", flush=True)
                self.reply(401, "password authentication failed")
                return False
            return True
        def do_GET(self):
            if self.path == "/healthz": return self.reply(200, "ok")
            if not self.authed(): return
            v = STORE.get(self.path)
            self.reply(200, v) if v is not None else self.reply(404, "no such invoice")
        def do_PUT(self):
            n = int(self.headers.get("Content-Length", 0)); body = self.rfile.read(n).decode()
            if not self.authed(): return
            STORE[self.path] = body
            self.reply(201, "stored")
    ThreadingHTTPServer(("0.0.0.0", 5000), H).serve_forever()
  api.py: |
    import os, urllib.request, urllib.error
    from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
    DB = os.environ["DB_URL"]; PW = os.environ["DB_PASSWORD"]
    def db(method, path, data=None):
        r = urllib.request.Request(DB + path, data=data, method=method, headers={"X-DB-Password": PW})
        return urllib.request.urlopen(r, timeout=3)
    class H(BaseHTTPRequestHandler):
        def log_message(self, fmt, *a): print(self.command, self.path, flush=True)
        def reply(self, code, body):
            b = body.encode()
            self.send_response(code); self.send_header("Content-Length", str(len(b))); self.end_headers(); self.wfile.write(b)
        def go(self, method):
            data = self.rfile.read(int(self.headers.get("Content-Length", 0))) if method == "PUT" else None
            try:
                with db(method, self.path, data) as r:
                    return self.reply(201 if method == "PUT" else 200, r.read().decode())
            except urllib.error.HTTPError as e:
                return self.reply(502 if e.code == 401 else e.code, "billing-api: database said %d %s\n" % (e.code, e.read().decode()))
            except Exception as e:
                return self.reply(502, "billing-api: database unreachable (%s)\n" % e)
        def do_GET(self):
            if self.path == "/healthz": return self.reply(200, "ok")
            if self.path.startswith("/invoices/"): return self.go("GET")
            self.reply(404, "not found")
        def do_POST(self):
            if self.path.startswith("/invoices/"): return self.go("PUT")
            self.reply(404, "not found")
    ThreadingHTTPServer(("0.0.0.0", 8080), H).serve_forever()
  export.py: |
    import os, sys, time, urllib.request, urllib.error
    r = urllib.request.Request(os.environ["DB_URL"] + "/invoices/export-%d" % time.time(), data=b"nightly export",
                               method="PUT", headers={"X-DB-Password": os.environ["DB_PASS"]})
    try:
        print("export:", urllib.request.urlopen(r, timeout=5).status, flush=True)
    except Exception as e:
        print("export failed:", e, flush=True)
        sys.exit(1)
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: billing-db
spec:
  replicas: 1
  selector:
    matchLabels: {app: billing-db}
  template:
    metadata:
      labels: {app: billing-db}
    spec:
      containers:
      - name: db
        image: python:3.12-alpine
        command: ["python", "-u", "/src/db.py"]
        env:
        - name: DB_ADMIN_PASSWORD
          valueFrom:
            secretKeyRef: {name: billing-db-engine, key: admin-password}
        ports:
        - {containerPort: 5000}
        readinessProbe:
          httpGet: {path: /healthz, port: 5000}
          periodSeconds: 3
        volumeMounts:
        - {name: src, mountPath: /src}
      volumes:
      - name: src
        configMap: {name: billing-src}
---
apiVersion: v1
kind: Service
metadata:
  name: billing-db
spec:
  selector: {app: billing-db}
  ports:
  - {port: 5000, targetPort: 5000}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: billing-api
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate: {maxSurge: 1, maxUnavailable: 1}
  selector:
    matchLabels: {app: billing-api}
  template:
    metadata:
      labels: {app: billing-api}
      annotations: {release: "2.4.0"}
    spec:
      containers:
      - name: api
        image: python:3.12-alpine
        command: ["python", "-u", "/src/api.py"]
        env:
        - {name: DB_URL, value: "http://billing-db:5000"}
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef: {name: db-credentials, key: password}
        ports:
        - {containerPort: 8080}
        readinessProbe:
          httpGet: {path: /healthz, port: 8080}
          periodSeconds: 3
        volumeMounts:
        - {name: src, mountPath: /src}
      volumes:
      - name: src
        configMap: {name: billing-src}
---
apiVersion: v1
kind: Service
metadata:
  name: billing-api
spec:
  selector: {app: billing-api}
  ports:
  - {port: 80, targetPort: 8080}
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: invoice-export
spec:
  schedule: "30 2 * * *"
  jobTemplate:
    spec:
      backoffLimit: 0
      template:
        spec:
          restartPolicy: Never
          containers:
          - name: export
            image: python:3.12-alpine
            command: ["python", "-u", "/src/export.py"]
            env:
            - {name: DB_URL, value: "http://billing-db:5000"}
            - name: DB_PASS
              valueFrom:
                secretKeyRef: {name: db-credentials, key: DB_PASS}
            volumeMounts:
            - {name: src, mountPath: /src}
          volumes:
          - name: src
            configMap: {name: billing-src}
YAML
wait_rollout billing-db 120 || exit 1
wait_rollout billing-api 120 || exit 1

# the half-finished rotation
kubectl -n "$NS" delete secret db-credentials >/dev/null
kubectl -n "$NS" patch deploy billing-api -p '{"spec":{"template":{"metadata":{"annotations":{"release":"2.4.1"}}}}}' >/dev/null
