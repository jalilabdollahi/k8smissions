#!/bin/bash
# Level 4: three members, three claims, each member's data is its own and persists.
. ../_fixtures/lib.sh
STS=postgres-cluster

if ! kubectl get statefulset $STS -n "$NS" >/dev/null 2>&1; then
  bad "StatefulSet $STS does not exist"
  exit 1
fi
SPEC=$(kubectl get statefulset $STS -n "$NS" -o jsonpath='{.spec.replicas}')
READY=$(kubectl get statefulset $STS -n "$NS" -o jsonpath='{.status.readyReplicas}')
if [ "${SPEC:-0}" -lt 3 ] || [ "${READY:-0}" -lt 3 ]; then
  bad "$STS has ${READY:-0} of ${SPEC:-0} members Ready (3 required)"
  exit 1
fi
ok "$READY of $SPEC members are Ready"

for i in 0 1 2; do
  phase=$(kubectl get pvc pgdata-$STS-$i -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null)
  if [ "$phase" != "Bound" ]; then
    bad "PVC pgdata-$STS-$i is ${phase:-missing}"
    exit 1
  fi
done
ok "pgdata-$STS-0, -1 and -2 are all Bound"

for i in 0 1 2; do
  id=$(kubectl exec -n "$NS" $STS-$i -- cat /var/lib/pgdata/node-id 2>/dev/null)
  if [ "$id" != "$STS-$i" ]; then
    bad "member $STS-$i sees data directory owner '${id:-none}'"
    exit 1
  fi
  kubectl exec -n "$NS" $STS-$i -- sh -c "echo mark-$i-$$ > /var/lib/pgdata/marker" >/dev/null 2>&1
done
ok "each member's data directory is its own"

kubectl delete pod $STS-0 $STS-1 $STS-2 -n "$NS" --wait=false >/dev/null 2>&1
sleep 3
kubectl wait pod/$STS-2 -n "$NS" --for=condition=Ready --timeout=90s >/dev/null 2>&1
for i in 0 1 2; do
  got=$(kubectl exec -n "$NS" $STS-$i -- cat /var/lib/pgdata/marker 2>/dev/null)
  if [ "$got" != "mark-$i-$$" ]; then
    bad "member $STS-$i lost its data after its pod was deleted"
    exit 1
  fi
done
ok "every member found its data again after its pod was replaced"
exit 0
exit 1
