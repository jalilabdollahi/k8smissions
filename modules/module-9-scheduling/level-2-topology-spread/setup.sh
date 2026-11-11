#!/bin/bash
# Replay "the other worker was cordoned when the pods were created": all pods land on worker 1, then worker 2 is released.
. ../_fixtures/lib.sh
a=$(worker_n 1); b=$(worker_n 2)
kubectl cordon "$b"
kubectl -n "$NS" apply -f - <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: catalog-api
  namespace: k8smissions
spec:
  replicas: 6
  selector:
    matchLabels:
      app.kubernetes.io/name: catalog-api
  template:
    metadata:
      labels:
        app.kubernetes.io/name: catalog-api
        app.kubernetes.io/part-of: storefront
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: DoNotSchedule
        nodeTaintsPolicy: Honor
        matchLabelKeys: [pod-template-hash]
        labelSelector:
          matchLabels:
            app: catalog
      containers:
      - name: api
        image: registry.k8s.io/pause:3.10
        resources:
          requests: {cpu: 10m, memory: 16Mi}
YAML
wait_pods_ready app.kubernetes.io/name=catalog-api 6 120 || exit 1
kubectl uncordon "$b"
