#!/bin/bash
# Two PriorityClasses, then a low-priority filler that leaves each worker with
# less free CPU than one checkout pod needs.
NS=${NS:-k8smissions}

kubectl apply -f - <<'YAML'
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: batch-low
  labels: {k8smissions/managed: "true"}
value: 1000
globalDefault: false
description: "Nightly batch work. Fine to be preempted."
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: platform-critical
  labels: {k8smissions/managed: "true"}
value: 100000
preemptionPolicy: Never
globalDefault: false
description: "Customer-facing platform services."
YAML

# free CPU (millicores) on every schedulable worker
free_on() {
  local node=$1
  local alloc used
  alloc=$(kubectl get node "$node" -o json | jq -r '.status.allocatable.cpu | if endswith("m") then rtrimstr("m")|tonumber else tonumber*1000 end')
  used=$(kubectl get pods -A --field-selector "spec.nodeName=$node" -o json | jq '[.items[] | select(.status.phase!="Succeeded" and .status.phase!="Failed") | .spec.containers[].resources.requests.cpu // "0" | if endswith("m") then rtrimstr("m")|tonumber else tonumber*1000 end] | add // 0')
  echo $((alloc - used))
}
min=999999
for n in $(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o name | cut -d/ -f2); do
  f=$(free_on "$n")
  [ "$f" -lt "$min" ] && min=$f
done
filler=$((min - 200))   # leaves under 200m (plus any difference between workers) on each node

kubectl -n "$NS" apply -f - <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: batch-reindex
  annotations: {k8smissions/original-replicas: "2"}
spec:
  replicas: 2
  selector:
    matchLabels: {app: batch-reindex}
  template:
    metadata:
      labels: {app: batch-reindex}
    spec:
      priorityClassName: batch-low
      terminationGracePeriodSeconds: 0
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels: {app: batch-reindex}
      containers:
      - name: reindex
        image: registry.k8s.io/pause:3.9
        resources:
          requests: {cpu: "${filler}m"}
YAML
kubectl -n "$NS" rollout status deploy/batch-reindex --timeout=120s
