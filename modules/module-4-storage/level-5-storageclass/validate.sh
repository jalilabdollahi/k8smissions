#!/bin/bash
# Level 5: reporter runs on a bound volume and its run log survives a restart.
. ../_fixtures/lib.sh

if ! kubectl get deployment reporter -n "$NS" >/dev/null 2>&1; then
  bad "Deployment reporter does not exist"
  exit 1
fi
POD=$(kubectl get pods -n "$NS" -l app=reporter --field-selector=status.phase=Running \
  -o jsonpath='{.items[?(@.status.containerStatuses[0].ready==true)].metadata.name}' | awk '{print $1}')
if [ -z "$POD" ]; then
  bad "reporter has no Ready pod"
  exit 1
fi
ok "$POD is Ready"

CLAIM=$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.spec.volumes[*].persistentVolumeClaim.claimName}')
if [ -z "$CLAIM" ]; then
  bad "the pod keeps its reports on no PersistentVolumeClaim"
  exit 1
fi
for c in $CLAIM; do
  if [ "$(kubectl get pvc "$c" -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null)" != "Bound" ]; then
    bad "PVC $c is not Bound"
    exit 1
  fi
done
ok "claim $CLAIM is Bound"

DEV=$(kubectl exec -n "$NS" "$POD" -- awk '$2=="/reports"{print $1}' /proc/mounts 2>/dev/null)
if [ -z "$DEV" ] || [ "$DEV" = "overlay" ]; then
  bad "/reports is not on a volume"
  exit 1
fi

FIRST=$(kubectl exec -n "$NS" "$POD" -- head -1 /reports/runs.log 2>/dev/null)
BEFORE=$(kubectl exec -n "$NS" "$POD" -- wc -l /reports/runs.log 2>/dev/null | awk '{print $1}')
kubectl delete pod "$POD" -n "$NS" --wait=false >/dev/null 2>&1
NEW=$(wait_replacement app=reporter "$POD" 60)
if [ -z "$NEW" ]; then
  bad "no replacement pod became Ready within 60s"
  exit 1
fi
AFTER=$(kubectl exec -n "$NS" "$NEW" -- wc -l /reports/runs.log 2>/dev/null | awk '{print $1}')
FIRST2=$(kubectl exec -n "$NS" "$NEW" -- head -1 /reports/runs.log 2>/dev/null)
if [ "${AFTER:-0}" -le "${BEFORE:-0}" ] || [ "$FIRST" != "$FIRST2" ]; then
  bad "the run log did not carry over to the new pod (lines before: $BEFORE, after: ${AFTER:-0})"
  exit 1
fi
ok "the run log kept its history across the restart ($BEFORE -> $AFTER lines)"
exit 0
exit 1
