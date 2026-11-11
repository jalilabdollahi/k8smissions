#!/bin/bash
# Level 1: search-indexer must survive its index load, 3 replicas, sized from observation.
. ../_fixtures/lib.sh
SEL=app=search-indexer

if ! kubectl get deployment search-indexer -n "$NS" >/dev/null 2>&1; then
  bad "Deployment search-indexer does not exist"
  exit 1
fi
want=$(kubectl get deployment search-indexer -n "$NS" -o jsonpath='{.spec.replicas}')
if [ "${want:-0}" -lt 3 ]; then
  bad "search-indexer is set to ${want:-0} replicas, the capacity plan needs 3"
  exit 1
fi

if ! wait_ready "$SEL" 3 70; then
  bad "only $(ready_count $SEL) of 3 search-indexer pods are Ready after 70s"
  exit 1
fi
ok "3 search-indexer pods are Ready (the index is loaded in each)"

PODS=$(live_pods "$SEL")
R0=$(restart_sum "$SEL")
WS=0
for p in $PODS; do
  m=$(cgroup_mem_mi "$p" indexer)
  [ "${m:-0}" -gt "$WS" ] && WS=$m
done
if [ "$WS" -lt 100 ]; then
  bad "could not read the working set of the pods (got ${WS}Mi)"
  exit 1
fi

LIM=$(kubectl get deployment search-indexer -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}')
REQ=$(kubectl get deployment search-indexer -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}')
if [ -z "$LIM" ] || [ -z "$REQ" ]; then
  bad "the container must keep a memory request and a memory limit"
  exit 1
fi
LIMM=$(mem_to_mi "$LIM"); REQM=$(mem_to_mi "$REQ")
if [ $((LIMM * 100)) -lt $((WS * 115)) ]; then
  bad "memory limit ${LIMM}Mi leaves under 15% headroom over the ${WS}Mi the process uses"
  exit 1
fi
ok "memory limit ${LIMM}Mi covers the ${WS}Mi working set with headroom"
if [ $((REQM * 100)) -lt $((WS * 80)) ]; then
  bad "memory request ${REQM}Mi is far below the ${WS}Mi the process uses"
  exit 1
fi
if [ "$REQM" -gt 400 ]; then
  bad "memory request ${REQM}Mi is far more than the process needs, it is reserving capacity nobody uses"
  exit 1
fi
ok "memory request ${REQM}Mi reflects real usage"

sleep 15
R1=$(restart_sum "$SEL")
if [ "$R1" != "$R0" ]; then
  bad "search-indexer pods restarted again during the 15s check ($R0 -> $R1)"
  exit 1
fi
ok "no restarts over 15s with the index loaded"

if [ "$(ready_count $SEL)" -lt 3 ]; then
  bad "fewer than 3 pods are Ready after the stability window"
  exit 1
fi
OUT=$(run_probe "http://search-indexer/stats" 6 2 10)
errs=$(echo "$OUT" | jq -r '.errors // "x"')
cnt=$(echo "$OUT" | jq -r '.count // 0')
if [ "$errs" != 0 ] || [ "${cnt:-0}" -lt 30 ]; then
  bad "requests to Service search-indexer failed (count=$cnt errors=$errs)"
  exit 1
fi
ok "Service search-indexer answered $cnt requests with 0 errors"
exit 0
exit 1
