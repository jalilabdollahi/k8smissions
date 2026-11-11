#!/bin/bash
# Two faults: the claim wants ReadWriteMany, and the default RollingUpdate cannot replace a pod that
# holds a ReadWriteOncePod volume. Access modes are immutable, so the claim is recreated.
kubectl rollout status deployment/ingest -n k8smissions --timeout=20s
kubectl get pods,pvc -n k8smissions
kubectl describe pvc shared-pvc -n k8smissions | tail -6
kubectl patch deployment ingest -n k8smissions --type=merge \
  -p '{"spec":{"strategy":{"type":"Recreate","rollingUpdate":null}}}'
kubectl wait --for=delete pod -l app=ingest -n k8smissions --timeout=60s || true
kubectl delete pvc shared-pvc -n k8smissions --wait=true --timeout=60s
kubectl apply -f - <<'YAML'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-pvc
  namespace: k8smissions
spec:
  accessModes: ["ReadWriteOncePod"]
  resources:
    requests:
      storage: 1Gi
YAML
kubectl rollout status deployment/ingest -n k8smissions --timeout=120s
