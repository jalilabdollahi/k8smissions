#!/bin/bash
# Size the encoder request at 60% of the smaller worker free CPU: one replica fits per worker, a third
# does not, although the two workers together have 2.0 nodes of room for 1.8 nodes of requests.
. ../_fixtures/lib.sh
fa=$(free_cpu_m "$(worker_n 1)"); fb=$(free_cpu_m "$(worker_n 2)")
min=$(( fa < fb ? fa : fb ))
req=$(( min * 6 / 10 ))

kubectl -n "$NS" create configmap encoder-capacity-plan \
  --from-literal=original-cpu-request-m="$req" \
  --from-literal=note="3 replicas x ${req}m = 3 x 60% of one node's free CPU; spreadsheet says it fits"

kubectl -n "$NS" apply -f - <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: video-encoder
  namespace: k8smissions
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate: {maxUnavailable: 2, maxSurge: 1}
  selector:
    matchLabels: {app: video-encoder}
  template:
    metadata:
      labels: {app: video-encoder}
    spec:
      containers:
      - name: encoder
        image: registry.k8s.io/pause:3.10
        resources:
          requests: {cpu: ${req}m, memory: 64Mi}
YAML
