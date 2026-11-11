#!/bin/bash
# Release 1 on nginx 1.26; broken.yaml then applies the new image. hostPort 9000
# forces the two pods onto different nodes.
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
../_fixtures/wait-ready.sh probe
kubectl -n "$NS" apply -f - <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
spec:
  replicas: 2
  selector:
    matchLabels: {app: api-server}
  template:
    metadata:
      labels: {app: api-server}
    spec:
      containers:
      - name: api
        image: nginx:1.26-alpine
        ports:
        - containerPort: 80
          hostPort: 9000
        readinessProbe:
          httpGet: {path: /, port: 80}
          periodSeconds: 2
        lifecycle:
          preStop:
            exec: {command: ["sleep", "4"]}
---
apiVersion: v1
kind: Service
metadata:
  name: api-server
spec:
  selector: {app: api-server}
  ports:
  - port: 80
    targetPort: 80
YAML
kubectl -n "$NS" rollout status deployment/api-server --timeout=120s
