#!/bin/bash
# Last quarter's state: pricing runs with the old rate. broken.yaml then raises it in the ConfigMap only.
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
kubectl -n "$NS" apply -f - <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: pricing-config
  namespace: k8smissions
data:
  TAX_RATE: "0.19"
  CURRENCY: EUR
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pricing
  namespace: k8smissions
spec:
  replicas: 2
  selector:
    matchLabels: {app: pricing}
  template:
    metadata:
      labels: {app: pricing}
    spec:
      containers:
      - name: api
        image: python:3.12-alpine
        envFrom:
        - configMapRef: {name: pricing-config}
        command:
        - python
        - -u
        - -c
        - |
          import os, json
          from http.server import BaseHTTPRequestHandler, HTTPServer
          class H(BaseHTTPRequestHandler):
              def do_GET(self):
                  body = json.dumps({"tax_rate": os.environ["TAX_RATE"], "currency": os.environ["CURRENCY"]}).encode()
                  self.send_response(200)
                  self.end_headers()
                  self.wfile.write(body)
          HTTPServer(("", 8080), H).serve_forever()
        ports:
        - containerPort: 8080
        readinessProbe:
          tcpSocket: {port: 8080}
          periodSeconds: 3
---
apiVersion: v1
kind: Service
metadata:
  name: pricing
  namespace: k8smissions
spec:
  selector:
    app: pricing
  ports:
  - port: 80
    targetPort: 8080
YAML
kubectl -n "$NS" rollout status deployment/pricing --timeout=120s
../_fixtures/wait-ready.sh probe
