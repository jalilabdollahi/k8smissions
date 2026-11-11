#!/bin/bash
# Level 14: a real rollout restart under the original quota, with traffic running through it.
. ../_fixtures/lib.sh
SEL=app=payments-web

if ! kubectl get deployment payments-web -n "$NS" >/dev/null 2>&1; then
  bad "Deployment payments-web does not exist"
  exit 1
fi
want=$(kubectl get deployment payments-web -n "$NS" -o jsonpath='{.spec.replicas}')
if [ "${want:-0}" -ne 4 ]; then
  bad "payments-web must run 4 replicas (it is set to ${want:-0})"
  exit 1
fi
HARD=$(kubectl get resourcequota compute -n "$NS" -o jsonpath='{.spec.hard.requests\.cpu}' 2>/dev/null)
if [ -z "$HARD" ]; then
  bad "ResourceQuota compute is missing"
  exit 1
fi
if [ "$(cpu_to_m "$HARD")" -gt 1500 ]; then
  bad "the quota was raised to $HARD: the finance team's limit is 1500m"
  exit 1
fi
ok "ResourceQuota compute is still ${HARD}"
REQ=$(kubectl get deployment payments-web -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}')
if [ -z "$REQ" ] || [ "$(cpu_to_m "$REQ")" -lt 10 ]; then
  bad "payments-web has no meaningful CPU request any more (${REQ:-none})"
  exit 1
fi
if ! wait_ready "$SEL" 4 60; then
  bad "only $(ready_count $SEL) of 4 payments-web pods are Ready before the test"
  exit 1
fi

PROBE=$(mktemp)
run_probe "http://payments-web/" 20 6 32 TIMEOUT=2 RETRY=1 > "$PROBE" &
PP=$!
sleep 3
kubectl rollout restart deployment/payments-web -n "$NS" >/dev/null 2>&1
if kubectl rollout status deployment/payments-web -n "$NS" --timeout=45s >/dev/null 2>&1; then DONE=1; else DONE=0; fi
wait $PP
OUT=$(cat "$PROBE"); rm -f "$PROBE"

if [ "$DONE" != 1 ]; then
  msg=$(kubectl get events -n "$NS" --field-selector reason=FailedCreate 2>/dev/null | tail -1 | cut -c1-160)
  bad "the rollout did not complete in 45s (latest event: ${msg:-none})"
  exit 1
fi
if ! wait_ready "$SEL" 4 20; then
  bad "only $(ready_count $SEL) of 4 payments-web pods are Ready after the rollout"
  exit 1
fi
ok "the rollout completed with 4 Ready replicas"
cnt=$(echo "$OUT" | jq -r '.count // 0'); errs=$(echo "$OUT" | jq -r '.errors // 999')
if [ "$cnt" -lt 300 ]; then
  bad "the probe completed only $cnt requests (could it be scheduled under the quota?)"
  exit 1
fi
if [ "$errs" -ne 0 ]; then
  bad "$errs of $cnt requests failed during the release"
  exit 1
fi
ok "$cnt requests during the release, no errors"
HARD2=$(kubectl get resourcequota compute -n "$NS" -o jsonpath='{.spec.hard.requests\.cpu}' 2>/dev/null)
if [ -z "$HARD2" ] || [ "$(cpu_to_m "$HARD2")" -gt 1500 ]; then
  bad "the quota was changed during the test"
  exit 1
fi
exit 0
exit 1
