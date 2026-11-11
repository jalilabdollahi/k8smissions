#!/bin/bash
# Level 12: the new claim must bind the old volume and the 2024 ledger must be readable.
. ../_fixtures/lib.sh

if ! kubectl get pv billing-pv >/dev/null 2>&1; then
  bad "PersistentVolume billing-pv no longer exists (it is the only pointer to the data)"
  exit 1
fi
POL=$(kubectl get pv billing-pv -o jsonpath='{.spec.persistentVolumeReclaimPolicy}')
if [ "$POL" != "Retain" ]; then
  bad "billing-pv reclaim policy is '$POL'; it must stay Retain"
  exit 1
fi

PHASE=$(kubectl get pvc billing-data -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$PHASE" != "Bound" ]; then
  bad "PVC billing-data is ${PHASE:-missing}, not Bound"
  exit 1
fi
if [ "$(kubectl get pvc billing-data -n "$NS" -o jsonpath='{.spec.volumeName}')" != "billing-pv" ]; then
  bad "PVC billing-data is bound to a different volume than billing-pv"
  exit 1
fi
ok "PVC billing-data is Bound to billing-pv (policy Retain)"

if ! kubectl get deployment billing-reader -n "$NS" >/dev/null 2>&1; then
  bad "Deployment billing-reader does not exist"
  exit 1
fi
POD=$(kubectl get pods -n "$NS" -l app=billing-reader --field-selector=status.phase=Running \
  -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$POD" ] || \
   [ "$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.status.containerStatuses[0].ready}')" != "true" ]; then
  bad "billing-reader has no Ready pod"
  exit 1
fi
ok "$POD is Ready"

ensure_probe || { bad "could not start the test client pod"; exit 1; }
LAST=$(pcurl http://billing-reader/ledger-2024.db | tail -1 | tr -d '\r\n')
if [ "$LAST" != "total,1675.40" ]; then
  bad "ledger-2024.db through Service billing-reader is missing or wrong (last line: '${LAST:-no answer}')"
  exit 1
fi
ok "ledger-2024.db is served from the old volume"
exit 0
exit 1
