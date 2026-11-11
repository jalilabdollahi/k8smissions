#!/bin/bash
# The shop is spread over both workers; one worker is booked for maintenance, the other
# one carries a leftover taint from a batch experiment.
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
set -- $(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[*].metadata.name}')
target=$1; other=$2
kubectl label node "$target" maintenance=pending --overwrite >/dev/null

kubectl -n "$NS" apply -f - <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout
spec:
  replicas: 2
  selector:
    matchLabels: {app: checkout}
  template:
    metadata:
      labels: {app: checkout}
    spec:
      terminationGracePeriodSeconds: 2
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              topologyKey: kubernetes.io/hostname
              labelSelector:
                matchLabels: {app: checkout}
      containers:
      - name: web
        image: python:3.12-alpine
        command: ["sh", "-c", "mkdir -p /srv && echo checkout-ok > /srv/index.html && cd /srv && exec python -m http.server 8080"]
        ports:
        - {containerPort: 8080}
        readinessProbe:
          httpGet: {path: /, port: 8080}
          periodSeconds: 3
---
apiVersion: v1
kind: Service
metadata:
  name: checkout
spec:
  selector: {app: checkout}
  ports:
  - {port: 80, targetPort: 8080}
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: checkout-pdb
spec:
  minAvailable: 3
  selector:
    matchLabels: {app: checkout}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: search
spec:
  replicas: 2
  selector:
    matchLabels: {app: search}
  template:
    metadata:
      labels: {app: search}
    spec:
      terminationGracePeriodSeconds: 2
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              topologyKey: kubernetes.io/hostname
              labelSelector:
                matchLabels: {app: search}
      containers:
      - name: web
        image: python:3.12-alpine
        command: ["sh", "-c", "echo search-ok > /cache/index.html && cd /cache && exec python -m http.server 8080"]
        ports:
        - {containerPort: 8080}
        readinessProbe:
          httpGet: {path: /, port: 8080}
          periodSeconds: 3
        volumeMounts:
        - {name: cache, mountPath: /cache}
      volumes:
      - name: cache
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: search
spec:
  selector: {app: search}
  ports:
  - {port: 80, targetPort: 8080}
---
apiVersion: v1
kind: Pod
metadata:
  name: report-scratch
  labels: {app: report-scratch}
spec:
  terminationGracePeriodSeconds: 1
  nodeSelector: {maintenance: pending}
  containers:
  - name: sleeper
    image: busybox:1.36
    command: ["sleep", "86400"]
YAML
wait_rollout checkout 120 && wait_rollout search 120 || exit 1

# exactly one pod of each Deployment on the maintenance node, one on the other worker
place() {
  for i in 1 2 3 4 5 6; do
    on_t=$(kubectl -n "$NS" get pods -l "app=$1" -o jsonpath='{range .items[*]}{.spec.nodeName}{"\n"}{end}' | grep -cx "$target")
    [ "$on_t" = 1 ] && return 0
    n=$other; [ "$on_t" -ge 2 ] && n=$target
    pod=$(kubectl -n "$NS" get pods -l "app=$1" --field-selector "spec.nodeName=$n" -o name | head -1)
    kubectl -n "$NS" delete "$pod" >/dev/null
    wait_rollout "$1" 90
  done
  return 1
}
place checkout && place search || exit 1
kubectl -n "$NS" wait --for=condition=Ready pod/report-scratch --timeout=60s >/dev/null || exit 1
kubectl taint node "$other" dedicated=batch:NoSchedule --overwrite >/dev/null
