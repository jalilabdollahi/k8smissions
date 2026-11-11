#!/bin/bash
# Build the v1 Deployment, then delete only the Deployment (orphaning its ReplicaSet and pods).
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
../_fixtures/wait-ready.sh probe
kubectl -n "$NS" apply -f - <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout-v1
spec:
  replicas: 3
  selector:
    matchLabels: {app: checkout}
  template:
    metadata:
      labels: {app: checkout}
    spec:
      containers:
      - name: web
        image: hashicorp/http-echo:1.0
        args: ["-listen=:8080", "-text=v1"]
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet: {path: /, port: 8080}
          periodSeconds: 2
YAML
kubectl -n "$NS" rollout status deployment/checkout-v1 --timeout=120s
kubectl -n "$NS" delete deployment checkout-v1 --cascade=orphan
