#!/bin/bash
# The pod waits for a claim named orders-db-data. Create it.
kubectl apply -n k8smissions -f - <<'YAML'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: orders-db-data
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 1Gi
YAML
kubectl rollout status deployment/orders-db -n k8smissions --timeout=90s
