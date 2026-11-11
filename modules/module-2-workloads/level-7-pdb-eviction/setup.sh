#!/bin/bash
# The client is a Deployment here (not the bare fixture pod) so that a plain
# `kubectl drain` is not blocked by an unmanaged pod.
kubectl -n "$NS" apply -f - <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: probe
spec:
  replicas: 1
  selector:
    matchLabels: {app: probe}
  template:
    metadata:
      labels: {app: probe}
    spec:
      terminationGracePeriodSeconds: 0
      containers:
      - name: curl
        image: curlimages/curl:8.10.1
        command: ["sleep", "86400"]
YAML
kubectl -n "$NS" rollout status deployment/probe --timeout=120s
