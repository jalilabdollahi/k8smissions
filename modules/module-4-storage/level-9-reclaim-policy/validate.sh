#!/bin/bash
# Level 9: the volume behind claim ledger-data must outlive the claim; nothing is deleted here.
. ../_fixtures/lib.sh

if ! kubectl get deployment ledger -n "$NS" >/dev/null 2>&1; then
  bad "Deployment ledger does not exist"
  exit 1
fi
POD=$(kubectl get pods -n "$NS" -l app=ledger --field-selector=status.phase=Running \
  -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$POD" ] || \
   [ "$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.status.containerStatuses[0].ready}')" != "true" ]; then
  bad "ledger has no Ready pod"
  exit 1
fi
ok "$POD is Ready"

if [ "$(kubectl get pvc ledger-data -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null)" != "Bound" ]; then
  bad "PVC ledger-data is missing or not Bound"
  exit 1
fi
SUM=$(kubectl exec -n "$NS" "$POD" -- tail -1 /data/2025-10-close.csv 2>/dev/null | tr -d '\r\n')
if [ "$SUM" != "total,42189.35" ]; then
  bad "the October close file is missing or changed (last line: '${SUM:-none}')"
  exit 1
fi
ok "the October close file is intact on ledger-data"

PV=$(kubectl get pvc ledger-data -n "$NS" -o jsonpath='{.spec.volumeName}')
POL=$(kubectl get pv "$PV" -o jsonpath='{.spec.persistentVolumeReclaimPolicy}' 2>/dev/null)
if [ "$POL" != "Retain" ]; then
  bad "the volume behind ledger-data would be ${POL:-unknown}d with its claim, not kept"
  exit 1
fi
ok "volume $PV is kept when its claim is deleted"

SPV=$(kubectl get pvc ledger-scratch -n "$NS" -o jsonpath='{.spec.volumeName}' 2>/dev/null)
SPOL=$(kubectl get pv "$SPV" -o jsonpath='{.spec.persistentVolumeReclaimPolicy}' 2>/dev/null)
if [ -z "$SPV" ] || [ "$SPOL" != "Delete" ]; then
  bad "the scratch volume (ledger-scratch) must keep reclaiming its space; its policy is '${SPOL:-unknown}'"
  exit 1
fi
ok "the scratch volume still cleans up after itself"
exit 0
exit 1
