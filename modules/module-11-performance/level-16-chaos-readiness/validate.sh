#!/bin/bash
# Level 16: replicas on different nodes, then a real node-loss drill (cordon + force delete) with a probe running through it.
. ../_fixtures/lib.sh
SEL=app.kubernetes.io/name=checkout-api

if ! kubectl get deployment checkout-api -n "$NS" >/dev/null 2>&1; then
  bad "Deployment checkout-api does not exist"
  exit 1
fi
want=$(kubectl get deployment checkout-api -n "$NS" -o jsonpath='{.spec.replicas}')
if [ "${want:-0}" -lt 2 ]; then
  bad "checkout-api must keep at least 2 replicas"
  exit 1
fi
if ! wait_ready "$SEL" "$want" 60; then
  bad "only $(ready_count $SEL) of $want checkout-api pods are Ready"
  exit 1
fi
NODES=$(kubectl get pods -n "$NS" -l "$SEL" -o json | jq -r '.items[] | select(.metadata.deletionTimestamp==null) | .spec.nodeName' | sort | uniq -c)
distinct=$(echo "$NODES" | grep -c .)
if [ "$distinct" -lt 2 ]; then
  bad "all checkout-api pods run on one node ($(echo "$NODES" | awk '{print $2}' | head -1))"
  exit 1
fi
ok "checkout-api runs on $distinct different nodes"
AFF=$(kubectl get deployment checkout-api -n "$NS" -o json | jq '[.spec.template.spec.affinity.podAntiAffinity // empty, (.spec.template.spec.topologySpreadConstraints // empty)] | length')
if [ "${AFF:-0}" -lt 1 ]; then
  bad "the placement rule (anti-affinity or topology spread) was removed from checkout-api"
  exit 1
fi

TARGET=$(echo "$NODES" | awk '{print $2}' | head -1)
PROBE=$(mktemp)
run_probe "http://checkout-api/" 20 6 20 TIMEOUT=2 RETRY=1 > "$PROBE" &
PP=$!
sleep 4
kubectl cordon "$TARGET" >/dev/null 2>&1
for p in $(kubectl get pods -n "$NS" -l "$SEL" --field-selector spec.nodeName="$TARGET" -o name); do
  kubectl delete "$p" -n "$NS" --force --grace-period=0 >/dev/null 2>&1
done
wait $PP
OUT=$(cat "$PROBE"); rm -f "$PROBE"
kubectl uncordon "$TARGET" >/dev/null 2>&1

cnt=$(echo "$OUT" | jq -r '.count // 0'); errs=$(echo "$OUT" | jq -r '.errors // 99999')
if [ "$cnt" -lt 150 ]; then
  bad "the probe only completed $cnt requests during the drill"
  exit 1
fi
if [ $((errs * 100)) -gt "$cnt" ]; then
  bad "node loss drill: $errs of $cnt requests failed (budget is 1%)"
  exit 1
fi
ok "node loss drill: $errs of $cnt requests failed"
if ! wait_ready "$SEL" "$want" 45; then
  bad "checkout-api did not recover to $want Ready pods after the node came back"
  exit 1
fi
ok "checkout-api is back to $want Ready replicas"
exit 0
exit 1
