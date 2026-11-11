#!/bin/bash
# Last year's archive: a directory on one worker, exposed as a static PV of class "archive".
NODE=$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[0].metadata.name}')
DIR=/var/k8sm/archive-2023

# seed the files on that node with a throw-away pod pinned to it
kubectl delete pod archive-seed -n "$NS" --ignore-not-found --wait=true >/dev/null
kubectl apply -f - >/dev/null <<YAML
apiVersion: v1
kind: Pod
metadata:
  name: archive-seed
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
        - |
          printf 'quarter,revenue\nQ1,1204550\nQ2,1311200\nQ3,1190875\nQ4,1498300\ntotal,5204925\n' > /archive/2023-summary.csv
          printf 'retention: 7 years\n' > /archive/README.txt
      volumeMounts:
        - name: archive
          mountPath: /archive
  volumes:
    - name: archive
      hostPath:
        path: $DIR
        type: DirectoryOrCreate
YAML
kubectl wait pod/archive-seed -n "$NS" --for=jsonpath='{.status.phase}'=Succeeded --timeout=120s >/dev/null || exit 1
kubectl delete pod archive-seed -n "$NS" --wait=false >/dev/null

kubectl apply -f - >/dev/null <<YAML
apiVersion: v1
kind: PersistentVolume
metadata:
  name: archive-2023
  labels:
    k8smissions/managed: "true"
spec:
  capacity:
    storage: 50Gi
  accessModes: ["ReadWriteOnce"]
  persistentVolumeReclaimPolicy: Retain
  storageClassName: archive
  local:
    path: $DIR
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values: ["$NODE"]
YAML
