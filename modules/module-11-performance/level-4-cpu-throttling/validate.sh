#!/bin/bash
# Level 4: latency under real load, and the cgroup's own throttling counters.
. ../_fixtures/lib.sh
SEL=app=quote-api

if ! kubectl get deployment quote-api -n "$NS" >/dev/null 2>&1; then
  bad "Deployment quote-api does not exist"
  exit 1
fi
want=$(kubectl get deployment quote-api -n "$NS" -o jsonpath='{.spec.replicas}')
if [ "${want:-0}" -lt 2 ]; then
  bad "quote-api must keep at least 2 replicas"
  exit 1
fi
if ! wait_ready "$SEL" 2 60; then
  bad "only $(ready_count $SEL) of 2 quote-api pods are Ready"
  exit 1
fi
REQ=$(kubectl get deployment quote-api -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}')
if [ -z "$REQ" ]; then
  bad "the container has no CPU request any more (it would be scheduled as BestEffort for CPU)"
  exit 1
fi
ok "CPU request is still set ($REQ)"

PODS=$(live_pods "$SEL")
P0=0; T0=0
for p in $PODS; do
  read -r np nt _ <<<"$(cgroup_cpu "$p" api)"
  P0=$((P0 + np)); T0=$((T0 + nt))
done

OUT=$(run_probe "http://quote-api/quote" 30 6 20 TIMEOUT=2)
cnt=$(echo "$OUT" | jq -r '.count // 0'); errs=$(echo "$OUT" | jq -r '.errors // 999'); p95=$(echo "$OUT" | jq -r '.p95_ms // 99999')

P1=0; T1=0
for p in $PODS; do
  read -r np nt _ <<<"$(cgroup_cpu "$p" api)"
  P1=$((P1 + np)); T1=$((T1 + nt))
done

if [ "$cnt" -lt 300 ]; then
  bad "the load probe only completed $cnt requests in 20s (expected about 600)"
  exit 1
fi
if [ "$errs" -ne 0 ]; then
  bad "$errs of $cnt requests failed or timed out at 30 req/s"
  exit 1
fi
if [ "$p95" -ge 150 ]; then
  bad "p95 latency is ${p95}ms at 30 req/s (limit 150ms)"
  exit 1
fi
ok "30 req/s for 20s: $cnt requests, 0 errors, p95 ${p95}ms"

DP=$((P1 - P0)); DT=$((T1 - T0))
if [ "$DP" -gt 0 ] && [ $((DT * 100)) -gt $((DP * 10)) ]; then
  bad "the pods were throttled in $DT of $DP CPU periods during the test"
  exit 1
fi
ok "throttled in $DT of $DP CPU periods during the test"
exit 0
exit 1
