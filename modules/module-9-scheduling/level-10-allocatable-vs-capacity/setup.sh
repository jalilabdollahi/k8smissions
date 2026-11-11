#!/bin/bash
# Other tenants reserve memory on each worker so that exactly 1400Mi stays free on both.
. ../_fixtures/lib.sh
i=0
for n in $(workers); do
  i=$((i+1))
  free=$(free_mem_mi "$n")
  req=$(( free - 1400 ))
  [ "$req" -gt 64 ] || { echo "worker $n has only ${free}Mi free, cannot build the scenario"; exit 1; }
  kubectl -n "$NS" apply -f - <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tenant-$( [ $i = 1 ] && echo analytics || echo search )
  namespace: k8smissions
spec:
  replicas: 1
  selector:
    matchLabels: {app: tenant-hold, slot: "$i"}
  template:
    metadata:
      labels: {app: tenant-hold, slot: "$i"}
    spec:
      nodeName: $n
      containers:
      - name: hold
        image: registry.k8s.io/pause:3.10
        resources:
          requests: {cpu: 10m, memory: ${req}Mi}
YAML
done
wait_pods_ready app=tenant-hold 2 120 || exit 1
