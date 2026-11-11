#!/bin/bash
# Level 1: orders-db must run on a bound volume that keeps its data.
. ../_fixtures/lib.sh
MP=/var/lib/orders-db

if ! kubectl get deployment orders-db -n "$NS" >/dev/null 2>&1; then
  bad "Deployment orders-db does not exist"
  exit 1
fi

POD=$(kubectl get pods -n "$NS" -l app=orders-db --field-selector=status.phase=Running \
  -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$POD" ]; then
  PHASE=$(kubectl get pods -n "$NS" -l app=orders-db -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
  bad "orders-db has no running pod (pod phase: ${PHASE:-none})"
  exit 1
fi
if [ "$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.status.containerStatuses[0].ready}')" != "true" ]; then
  bad "$POD is Running but not Ready"
  exit 1
fi
ok "$POD is Running and Ready"

CLAIMS=$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.spec.volumes[*].persistentVolumeClaim.claimName}')
if [ -z "$CLAIMS" ]; then
  bad "the pod does not use a PersistentVolumeClaim"
  exit 1
fi
for c in $CLAIMS; do
  phase=$(kubectl get pvc "$c" -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null)
  if [ "$phase" != "Bound" ]; then
    bad "PVC $c is ${phase:-missing}, not Bound"
    exit 1
  fi
  ok "PVC $c is Bound"
done

DEV=$(kubectl exec -n "$NS" "$POD" -- awk -v m="$MP" '$2==m{print $1}' /proc/mounts 2>/dev/null)
if [ -z "$DEV" ] || [ "$DEV" = "overlay" ]; then
  bad "nothing is mounted at $MP (it is on the container's own filesystem)"
  exit 1
fi
ok "a volume is mounted at $MP"

TOKEN="check-$(date +%s)"
kubectl exec -n "$NS" "$POD" -- sh -c "echo $TOKEN > $MP/validate-marker" >/dev/null 2>&1
kubectl delete pod "$POD" -n "$NS" --wait=false >/dev/null 2>&1
NEW=$(wait_replacement app=orders-db "$POD" 60)
if [ -z "$NEW" ]; then
  bad "no replacement pod became Ready within 60s after deleting $POD"
  exit 1
fi
GOT=$(kubectl exec -n "$NS" "$NEW" -- cat "$MP/validate-marker" 2>/dev/null)
if [ "$GOT" != "$TOKEN" ]; then
  bad "data written before the pod was deleted is gone in $NEW"
  exit 1
fi
ok "data written to $MP survived replacing the pod"
exit 0
exit 1
