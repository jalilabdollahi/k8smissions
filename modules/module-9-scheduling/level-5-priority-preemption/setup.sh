#!/bin/bash
# Fill both workers with 8 low-priority sandbox pods (4 per worker, sized from the real free CPU),
# then create the high-priority pay-gateway that cannot preempt them.
. ../_fixtures/lib.sh
fa=$(free_cpu_m "$(worker_n 1)"); fb=$(free_cpu_m "$(worker_n 2)")
min=$(( fa < fb ? fa : fb ))
req=$(( min / 4 ))

kubectl apply -f - <<YAML
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: sandbox-low
  labels: {k8smissions/managed: "true"}
value: 1000
description: "developer sandboxes"
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: payments-high
  labels: {k8smissions/managed: "true"}
value: 100000
preemptionPolicy: Never
description: "payments production workloads"
YAML

kubectl -n "$NS" apply -f - <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dev-sandbox
  namespace: k8smissions
spec:
  replicas: 8
  selector:
    matchLabels: {app: dev-sandbox}
  template:
    metadata:
      labels: {app: dev-sandbox}
    spec:
      priorityClassName: sandbox-low
      terminationGracePeriodSeconds: 1
      containers:
      - name: env
        image: registry.k8s.io/pause:3.10
        resources:
          requests: {cpu: ${req}m, memory: 16Mi}
YAML
wait_pods_ready app=dev-sandbox 8 150 || exit 1

kubectl -n "$NS" apply -f - <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pay-gateway
  namespace: k8smissions
spec:
  replicas: 2
  selector:
    matchLabels: {app: pay-gateway}
  template:
    metadata:
      labels: {app: pay-gateway}
    spec:
      priorityClassName: payments-high
      containers:
      - name: gateway
        image: registry.k8s.io/pause:3.10
        resources:
          requests: {cpu: ${req}m, memory: 16Mi}
YAML
