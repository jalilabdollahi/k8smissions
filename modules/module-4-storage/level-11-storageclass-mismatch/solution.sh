#!/bin/bash
# The claim has no class, so the default class gave it a fresh empty volume; a class cannot
# be changed on an existing claim, so recreate it with the class of the archive volume.
kubectl get pv,pvc -n k8smissions
kubectl get pv archive-2023 -o jsonpath='{.spec.storageClassName}{"\n"}'
kubectl scale deployment archive-reader -n k8smissions --replicas=0
kubectl wait --for=delete pod -l app=archive-reader -n k8smissions --timeout=60s
kubectl delete pvc archive -n k8smissions
kubectl apply -f - <<'YAML'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: archive
  namespace: k8smissions
spec:
  accessModes: ["ReadWriteOnce"]
  storageClassName: archive
  resources:
    requests:
      storage: 10Gi
YAML
kubectl scale deployment archive-reader -n k8smissions --replicas=1
kubectl rollout status deployment/archive-reader -n k8smissions --timeout=100s
