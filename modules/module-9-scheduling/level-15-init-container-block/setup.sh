#!/bin/bash
# Two reservation pods leave exactly 1000Mi of memory unreserved on each worker.
. ../_fixtures/lib.sh
i=0
for n in $(workers); do
  i=$((i+1))
  free=$(free_mem_mi "$n")
  hold=$(( free - 1000 ))
  [ "$hold" -gt 64 ] || { echo "worker $n has only ${free}Mi free, cannot build the scenario"; exit 1; }
  kubectl -n "$NS" apply -f - <<YAML
apiVersion: v1
kind: Pod
metadata:
  name: reserved-capacity-$i
  namespace: k8smissions
  labels: {app: reserved-capacity}
  annotations:
    note: "memory held back for the settlement team's quarter-end run"
spec:
  nodeName: $n
  containers:
  - name: hold
    image: registry.k8s.io/pause:3.10
    resources:
      requests: {cpu: 10m, memory: ${hold}Mi}
YAML
done
wait_pods_ready app=reserved-capacity 2 120 || exit 1
