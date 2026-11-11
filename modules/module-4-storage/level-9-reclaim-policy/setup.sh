#!/bin/bash
# The volumes are provisioned dynamically by the default class, so the PVs have generated
# names and no managed label. Bring the workload up, then label the PVs so the engine
# deletes them (a Retain PV would otherwise outlive the level).
kubectl apply -f broken.yaml >/dev/null
kubectl rollout status deployment/ledger -n "$NS" --timeout=150s >/dev/null || exit 1
for c in ledger-data ledger-scratch; do
  pv=$(kubectl get pvc "$c" -n "$NS" -o jsonpath='{.spec.volumeName}')
  [ -n "$pv" ] && kubectl label pv "$pv" k8smissions/managed=true --overwrite >/dev/null
done
exit 0
