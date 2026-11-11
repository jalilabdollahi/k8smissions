#!/bin/bash
# Release 1.x is live and healthy before the broken 2.0 rollout is applied by broken.yaml.
NS=${NS:-k8smissions}
kubectl -n "$NS" apply -f - <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: docs-site-conf-v1
data:
  default.conf: |
    server {
      listen 8080;
      default_type text/plain;
      location = /healthz { return 200 "ok\n"; }
      location / { return 200 "docs-site 1.9 - classic theme\n"; }
    }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: docs-site
  annotations:
    release: "1.9"
spec:
  replicas: 3
  selector:
    matchLabels: {app: docs-site}
  strategy:
    type: RollingUpdate
    rollingUpdate: {maxSurge: 1, maxUnavailable: 0}
  template:
    metadata:
      labels: {app: docs-site}
    spec:
      containers:
      - name: nginx
        image: nginx:1.27-alpine
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet: {path: /healthz, port: 8080}
          periodSeconds: 3
        volumeMounts:
        - {name: conf, mountPath: /etc/nginx/conf.d}
      volumes:
      - name: conf
        configMap: {name: docs-site-conf-v1}
YAML
kubectl -n "$NS" rollout status deploy/docs-site --timeout=120s
