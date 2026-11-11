#!/bin/bash
# 8 search-indexer pods piled on worker 1 (worker 2 cordoned while they start), each requesting
# 10% of a worker's allocatable CPU, so the loaded worker sits at about 80% of CPU requests.
. ../_fixtures/lib.sh
a=$(worker_n 1); b=$(worker_n 2)
alloc=$(cpu_to_m "$(kubectl get node "$a" -o jsonpath='{.status.allocatable.cpu}')")
req=$(( alloc / 10 ))

kubectl cordon "$b"
kubectl -n "$NS" apply -f - <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: search-indexer
  namespace: k8smissions
spec:
  replicas: 8
  selector:
    matchLabels: {app: search-indexer}
  template:
    metadata:
      labels: {app: search-indexer}
    spec:
      containers:
      - name: indexer
        image: registry.k8s.io/pause:3.10
        resources:
          requests: {cpu: ${req}m, memory: 16Mi}
YAML
wait_pods_ready app=search-indexer 8 150 || exit 1
kubectl uncordon "$b"
