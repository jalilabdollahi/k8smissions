#!/bin/bash
# Level 17: wedge one pod and measure the success rate through the Service, then check the wedged pod is restarted by its probes.
. ../_fixtures/lib.sh
SEL=app=ledger-api

if ! kubectl get deployment ledger-api -n "$NS" >/dev/null 2>&1; then
  bad "Deployment ledger-api does not exist"
  exit 1
fi
want=$(kubectl get deployment ledger-api -n "$NS" -o jsonpath='{.spec.replicas}')
if [ "${want:-0}" -lt 4 ]; then
  bad "ledger-api must keep 4 replicas (it has ${want:-0})"
  exit 1
fi
if ! wait_ready "$SEL" 4 60; then
  bad "only $(ready_count $SEL) of 4 ledger-api pods are Ready before the test"
  exit 1
fi
if ! kubectl get deployment ledger-api -n "$NS" -o json | jq -e '.spec.template.spec.containers[0].livenessProbe' >/dev/null; then
  bad "ledger-api no longer has a liveness probe: a wedged pod would never be restarted"
  exit 1
fi

restarts() { kubectl get pods -n "$NS" -l "$SEL" -o json | jq -r '.items[] | select(.metadata.deletionTimestamp==null) | "\(.metadata.name) \(.status.containerStatuses[0].restartCount)"'; }
BEFORE=$(restarts)
VICTIM=$(echo "$BEFORE" | head -1 | awk '{print $1}')
VR0=$(echo "$BEFORE" | awk -v v="$VICTIM" '$1==v{print $2}')

PROBE=$(mktemp)
run_probe "http://ledger-api/work" 25 10 24 TIMEOUT=1 RETRY=1 > "$PROBE" &
PP=$!
sleep 3
kubectl exec -n "$NS" "$VICTIM" -- python -c "import urllib.request;urllib.request.urlopen('http://127.0.0.1:8080/debug/wedge',timeout=3)" >/dev/null 2>&1
wait $PP
OUT=$(cat "$PROBE"); rm -f "$PROBE"
cnt=$(echo "$OUT" | jq -r '.count // 0'); errs=$(echo "$OUT" | jq -r '.errors // 99999')
if [ "$cnt" -lt 300 ]; then
  bad "the probe completed only $cnt requests in the window"
  exit 1
fi
if [ $((errs * 100)) -gt $((cnt * 2)) ]; then
  bad "with one wedged pod, $errs of $cnt requests failed (budget is 2%)"
  exit 1
fi
ok "one wedged pod: $errs of $cnt requests failed"

# the wedged pod must be restarted by its own liveness probe
end=$((SECONDS + 22)); restarted=0
while [ $SECONDS -lt $end ]; do
  VR1=$(restarts | awk -v v="$VICTIM" '$1==v{print $2}')
  [ "${VR1:-$VR0}" -gt "$VR0" ] && { restarted=1; break; }
  sleep 2
done
if [ "$restarted" != 1 ]; then
  bad "the wedged pod $VICTIM was still not restarted by its liveness probe 46 seconds after it hung"
  exit 1
fi
ok "the wedged pod was restarted by its liveness probe"
OTHERS=$(restarts | awk -v v="$VICTIM" '$1!=v')
while read -r name n; do
  b=$(echo "$BEFORE" | awk -v p="$name" '$1==p{print $2}')
  if [ -n "$b" ] && [ "$n" -gt "$b" ]; then
    bad "healthy pod $name was restarted too ($b to $n): the liveness probe is too twitchy"
    exit 1
  fi
done <<<"$OTHERS"
ok "no healthy pod was restarted"
if ! wait_ready "$SEL" 4 40; then
  bad "ledger-api is back to only $(ready_count $SEL) Ready pods"
  exit 1
fi
exit 0
exit 1
