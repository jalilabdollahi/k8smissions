#!/bin/bash
# Replay "both replicas were scheduled while the other worker was cordoned": they land on one node, then it is released.
. ../_fixtures/lib.sh
b=$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o name | sed -n 2p)
[ -n "$b" ] && kubectl cordon "$b" >/dev/null
trap '[ -n "$b" ] && kubectl uncordon "$b" >/dev/null' EXIT
kubectl -n "$NS" apply -f - <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout-api
  namespace: k8smissions
spec:
  replicas: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: checkout-api
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 0
      maxUnavailable: 1
  template:
    metadata:
      labels:
        app.kubernetes.io/name: checkout-api
        app.kubernetes.io/part-of: storefront
    spec:
      terminationGracePeriodSeconds: 5
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - topologyKey: kubernetes.io/hostname
            labelSelector:
              matchLabels:
                app: checkout-api
      containers:
      - name: api
        image: nginx:1.27-alpine
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet: {path: /, port: 80}
          periodSeconds: 2
        resources:
          requests: {cpu: 20m, memory: 16Mi}
          limits: {memory: 64Mi}
YAML
wait_ready app.kubernetes.io/name=checkout-api 2 90 || exit 1
