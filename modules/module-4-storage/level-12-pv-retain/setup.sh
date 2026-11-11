#!/bin/bash
# Re-creates the aftermath of a deleted namespace: PV billing-pv (Retain) keeps its data
# and a claimRef to a claim that no longer exists.
NODE=$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[0].metadata.name}')
DIR=/var/k8sm/billing-2024

kubectl delete pod billing-seed -n "$NS" --ignore-not-found --wait=true >/dev/null
kubectl apply -f - >/dev/null <<YAML
apiVersion: v1
kind: Pod
metadata:
  name: billing-seed
  namespace: $NS
spec:
  nodeName: $NODE
  restartPolicy: Never
  containers:
    - name: seed
      image: busybox:1.36
      command:
        - sh
        - -c
        - printf 'invoice,amount\nINV-24001,310.00\nINV-24002,1275.50\nINV-24003,89.90\ntotal,1675.40\n' > /billing/ledger-2024.db
      volumeMounts:
        - name: billing
          mountPath: /billing
  volumes:
    - name: billing
      hostPath:
        path: $DIR
        type: DirectoryOrCreate
YAML
kubectl wait pod/billing-seed -n "$NS" --for=jsonpath='{.status.phase}'=Succeeded --timeout=120s >/dev/null || exit 1
kubectl delete pod billing-seed -n "$NS" --wait=false >/dev/null

kubectl apply -f - >/dev/null <<YAML
apiVersion: v1
kind: PersistentVolume
metadata:
  name: billing-pv
  labels:
    k8smissions/managed: "true"
spec:
  capacity:
    storage: 20Gi
  accessModes: ["ReadWriteOnce"]
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""
  local:
    path: $DIR
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values: ["$NODE"]
---
apiVersion: v1
kind: Namespace
metadata:
  name: billing-v1
  labels:
    k8smissions/managed: "true"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: billing-data
  namespace: billing-v1
spec:
  accessModes: ["ReadWriteOnce"]
  storageClassName: ""
  volumeName: billing-pv
  resources:
    requests:
      storage: 10Gi
YAML
kubectl wait pvc/billing-data -n billing-v1 --for=jsonpath='{.status.phase}'=Bound --timeout=60s >/dev/null || exit 1

# the old team's namespace is deleted, as in the incident
kubectl delete namespace billing-v1 --wait=true --timeout=90s >/dev/null
kubectl wait pv/billing-pv --for=jsonpath='{.status.phase}'=Released --timeout=60s >/dev/null || exit 1
exit 0
