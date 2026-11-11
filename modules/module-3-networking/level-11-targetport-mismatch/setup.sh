#!/bin/bash
# release 4.1 is rolled out first so the Deployment has a real rollout history;
# broken.yaml then applies release 4.2 over it
kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
cat <<'YAML' | kubectl -n "$NS" apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout
spec:
  replicas: 3
  selector:
    matchLabels: {app: checkout}
  template:
    metadata:
      labels: {app: checkout}
      annotations:
        kubernetes.io/change-cause: "release 4.1"
    spec:
      containers:
      - name: web
        image: hashicorp/http-echo:1.0
        args: ["-listen=:8080", "-text=checkout v4.1"]
        ports:
        - name: http
          containerPort: 8080
        readinessProbe:
          tcpSocket: {port: 8080}
          periodSeconds: 3
YAML
kubectl -n "$NS" rollout status deploy/checkout --timeout=120s
../_fixtures/wait-ready.sh probe
