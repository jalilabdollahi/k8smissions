#!/bin/bash
# The claim names a class the cluster does not have. See what classes exist, then provide gp3.
kubectl get storageclass
kubectl describe pvc reports-data -n k8smissions | tail -5
kubectl get storageclass standard -o jsonpath='{.provisioner}{"\n"}'
kubectl apply -f - <<'YAML'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
YAML
kubectl rollout status deployment/reporter -n k8smissions --timeout=100s
