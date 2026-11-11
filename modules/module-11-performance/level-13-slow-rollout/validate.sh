#!/bin/bash
# Level 13: trigger a real rollout; measure its duration, the availability floor and the errors seen by a probe.
. ../_fixtures/lib.sh
SEL=app=image-resizer

if ! kubectl get deployment image-resizer -n "$NS" >/dev/null 2>&1; then
  bad "Deployment image-resizer does not exist"
  exit 1
fi
want=$(kubectl get deployment image-resizer -n "$NS" -o jsonpath='{.spec.replicas}')
if [ "${want:-0}" -ne 40 ]; then
  bad "image-resizer must keep 40 replicas (it has ${want:-0})"
  exit 1
fi
if ! wait_ready "$SEL" 40 60; then
  bad "only $(ready_count $SEL) of 40 pods are Ready before the test"
  exit 1
fi
# wait until a previous rollout (the player's own edit) is completely finished
for _ in $(seq 1 20); do
  kubectl get deployment image-resizer -n "$NS" -o json | jq -e '.status.updatedReplicas==40 and .status.replicas==40 and .status.availableReplicas==40' >/dev/null && break
  sleep 2
done

PROBE=$(mktemp)
run_probe "http://image-resizer/" 20 6 36 TIMEOUT=2 RETRY=1 > "$PROBE" &
PPID_=$!
sleep 2
kubectl rollout restart deployment/image-resizer -n "$NS" >/dev/null 2>&1
T0=$SECONDS; MIN=40; DONE=0
while [ $((SECONDS - T0)) -lt 30 ]; do
  J=$(kubectl get deployment image-resizer -n "$NS" -o json)
  av=$(echo "$J" | jq '.status.availableReplicas // 0')
  [ "$av" -lt "$MIN" ] && MIN=$av
  if echo "$J" | jq -e '.status.observedGeneration>=.metadata.generation and .status.updatedReplicas==40 and .status.replicas==40 and .status.availableReplicas==40' >/dev/null; then
    DONE=1; break
  fi
  sleep 1
done
TOOK=$((SECONDS - T0))
wait $PPID_
OUT=$(cat "$PROBE"); rm -f "$PROBE"

if [ "$DONE" != 1 ]; then
  bad "the rollout was still not complete after 30 seconds ($(kubectl get deployment image-resizer -n "$NS" -o jsonpath='{.status.updatedReplicas}') of 40 pods updated)"
  exit 1
fi
ok "the rollout completed in ${TOOK}s"
if [ "$MIN" -lt 30 ]; then
  bad "available replicas dropped to $MIN during the rollout (floor is 30 of 40)"
  exit 1
fi
ok "available replicas never dropped below $MIN"
cnt=$(echo "$OUT" | jq -r '.count // 0'); errs=$(echo "$OUT" | jq -r '.errors // 999')
if [ "$cnt" -lt 300 ]; then
  bad "the probe only completed $cnt requests during the rollout"
  exit 1
fi
if [ "$errs" -ne 0 ]; then
  bad "$errs of $cnt requests failed while the rollout was running"
  exit 1
fi
ok "$cnt requests during the rollout, no errors"
exit 0
exit 1
