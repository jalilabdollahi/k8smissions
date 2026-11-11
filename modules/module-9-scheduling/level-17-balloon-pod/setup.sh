#!/bin/bash
# Placeholder pods reserve 28% of a worker's free CPU each, 3 per worker; checkout asks 18% each.
. ../_fixtures/lib.sh
a=$(worker_n 1); b=$(worker_n 2)
fa=$(free_cpu_m "$a"); fb=$(free_cpu_m "$b")
min=$fa; [ "$fb" -lt "$min" ] && min=$fb
max=$fa; [ "$fb" -gt "$max" ] && max=$fb
if [ $((max * 100)) -ge $((min * 112)) ]; then echo "workers differ too much in free cpu ($fa vs $fb)"; exit 1; fi
rsv=$(( min * 28 / 100 ))
chk=$(( min * 18 / 100 ))
kubectl -n "$NS" apply -f - <<YAML
apiVersion: v1
kind: ConfigMap
metadata: {name: reserve-plan, namespace: k8smissions}
data:
  replicas: "6"
  cpu-per-pod-m: "$rsv"
  checkout-cpu-m: "$chk"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: capacity-reserve
  namespace: k8smissions
spec:
  replicas: 6
  strategy: {type: Recreate}
  selector:
    matchLabels: {app: capacity-reserve}
  template:
    metadata:
      labels: {app: capacity-reserve}
    spec:
      containers:
      - name: pause
        image: registry.k8s.io/pause:3.10
        resources:
          requests: {cpu: ${rsv}m, memory: 16Mi}
YAML
wait_pods_ready app=capacity-reserve 6 120 || exit 1
kubectl -n "$NS" apply -f - <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout
  namespace: k8smissions
spec:
  replicas: 4
  selector:
    matchLabels: {app: checkout}
  template:
    metadata:
      labels: {app: checkout}
    spec:
      containers:
      - name: checkout
        image: nginx:1.27-alpine
        ports: [{containerPort: 80}]
        readinessProbe:
          httpGet: {path: /, port: 80}
        resources:
          requests: {cpu: ${chk}m, memory: 32Mi}
YAML
