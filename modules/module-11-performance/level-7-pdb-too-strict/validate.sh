#!/bin/bash
# Level 7: drain each worker in turn through the eviction API (what kubectl drain does), under traffic.
. ../_fixtures/lib.sh

for d in orders-api orders-cache; do
  if ! kubectl get deployment "$d" -n "$NS" >/dev/null 2>&1; then
    bad "Deployment $d does not exist"
    exit 1
  fi
  if ! kubectl get pdb "$d" -n "$NS" >/dev/null 2>&1; then
    bad "PodDisruptionBudget $d is gone: the budgets must stay to protect the pods"
    exit 1
  fi
done
if [ "$(kubectl get deployment orders-api -n "$NS" -o jsonpath='{.spec.replicas}')" -lt 3 ]; then
  bad "orders-api must keep its 3 replicas"
  exit 1
fi
if [ "$(kubectl get deployment orders-cache -n "$NS" -o jsonpath='{.spec.replicas}')" -lt 1 ]; then
  bad "orders-cache must keep at least 1 replica"
  exit 1
fi
if ! wait_ready app=orders-api 3 40 || ! wait_ready app=orders-cache 1 40; then
  bad "orders-api and orders-cache must be Ready before a drain"
  exit 1
fi

# the budgets must still protect: api may lose at most one pod, and must not allow all of them
api_desired=$(kubectl get pdb orders-api -n "$NS" -o jsonpath='{.status.desiredHealthy}')
api_expected=$(kubectl get pdb orders-api -n "$NS" -o jsonpath='{.status.expectedPods}')
cache_expected=$(kubectl get pdb orders-cache -n "$NS" -o jsonpath='{.status.expectedPods}')
if [ "${api_expected:-0}" -lt 3 ] || [ "${api_desired:-0}" -lt 2 ]; then
  bad "the orders-api budget no longer protects the pods (it must keep at least 2 of 3 up)"
  exit 1
fi
if [ "${cache_expected:-0}" -lt 1 ]; then
  bad "the orders-cache budget no longer selects its pods"
  exit 1
fi

WORKERS=$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
cleanup() { for w in $WORKERS; do kubectl uncordon "$w" >/dev/null 2>&1; done; }
trap cleanup EXIT

OUTF=$(mktemp)
run_probe "http://orders-api/" 10 4 45 TIMEOUT=3 RETRY=1 > "$OUTF" &
PROBE=$!
sleep 3

for w in $WORKERS; do
  kubectl cordon "$w" >/dev/null 2>&1
  end=$((SECONDS + 22))
  left=1
  while [ $SECONDS -lt $end ]; do
    PODS=$(kubectl get pods -n "$NS" -o json | jq -r --arg n "$w" \
      '.items[] | select(.spec.nodeName==$n and .metadata.deletionTimestamp==null and (.metadata.labels.app|test("^orders-"))) | .metadata.name')
    if [ -z "$PODS" ]; then left=0; break; fi
    for p in $PODS; do
      echo "{\"apiVersion\":\"policy/v1\",\"kind\":\"Eviction\",\"metadata\":{\"name\":\"$p\",\"namespace\":\"$NS\"}}" |
        kubectl create --raw "/api/v1/namespaces/$NS/pods/$p/eviction" -f - >/dev/null 2>&1
    done
    sleep 2
  done
  if [ "$left" -ne 0 ]; then
    kill $PROBE 2>/dev/null; rm -f "$OUTF"
    bad "draining $w stalled: eviction of orders pods keeps being refused by a PodDisruptionBudget"
    exit 1
  fi
  ok "$w drained"
  kubectl uncordon "$w" >/dev/null 2>&1
  if ! wait_ready app=orders-api 3 30 || ! wait_ready app=orders-cache 1 30; then
    kill $PROBE 2>/dev/null; rm -f "$OUTF"
    bad "orders pods did not come back Ready after draining $w"
    exit 1
  fi
done

wait $PROBE
OUT=$(cat "$OUTF"); rm -f "$OUTF"
cnt=$(echo "$OUT" | jq -r '.count // 0'); errs=$(echo "$OUT" | jq -r '.errors // 999')
if [ "$cnt" -lt 100 ]; then
  bad "the probe only completed $cnt requests during the drains"
  exit 1
fi
if [ "$errs" -ne 0 ]; then
  bad "$errs of $cnt requests to orders-api failed during the drains"
  exit 1
fi
ok "orders-api answered $cnt requests during both drains, 0 failed"
exit 0
exit 1
