#!/bin/bash
# Find the volume behind the ledger claim and change its policy; the class is not touched.
kubectl get pvc -n k8smissions
PV=$(kubectl get pvc ledger-data -n k8smissions -o jsonpath='{.spec.volumeName}')
kubectl get pv "$PV" -o wide
kubectl patch pv "$PV" -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
kubectl get pv "$PV"
