#!/bin/bash
# Level 6: gated pods become Ready, and a rollout restart never sends traffic to a cold pod.
. ../_fixtures/lib.sh
SEL=app=catalog-web

for d in catalog-web warmup-gate; do
  if ! kubectl get deployment "$d" -n "$NS" >/dev/null 2>&1; then
    bad "Deployment $d does not exist"
    exit 1
  fi
done
want=$(kubectl get deployment catalog-web -n "$NS" -o jsonpath='{.spec.replicas}')
if [ "${want:-0}" -lt 3 ]; then
  bad "catalog-web must keep 3 replicas"
  exit 1
fi
if ! wait_ready "$SEL" 3 40; then
  n=$(kubectl get pods -n "$NS" -l "$SEL" -o json | jq '[.items[] | select(all(.status.containerStatuses[]?; .ready==true))] | length')
  bad "only $(ready_count $SEL) of 3 catalog-web pods are Ready ($n have all containers Ready)"
  exit 1
fi
ok "3 catalog-web pods are Ready"

OUTF=$(mktemp)
run_probe "http://catalog-web/" 10 4 40 TIMEOUT=3 > "$OUTF" &
PROBE=$!
sleep 4
kubectl rollout restart deployment/catalog-web -n "$NS" >/dev/null 2>&1
if ! kubectl rollout status deployment/catalog-web -n "$NS" --timeout=50s >/dev/null 2>&1; then
  kill $PROBE 2>/dev/null
  rm -f "$OUTF"
  bad "the rollout restart of catalog-web did not complete within 50s"
  exit 1
fi
ok "rollout restart completed"
wait $PROBE
OUT=$(cat "$OUTF"); rm -f "$OUTF"
cnt=$(echo "$OUT" | jq -r '.count // 0'); errs=$(echo "$OUT" | jq -r '.errors // 999')
if [ "$cnt" -lt 150 ]; then
  bad "the probe only completed $cnt requests during the rollout"
  exit 1
fi
if [ "$errs" -ne 0 ]; then
  bad "$errs of $cnt requests failed during the rollout (traffic reached pods that were not warm)"
  exit 1
fi
ok "$cnt requests during the rollout, 0 failed"
if [ "$(ready_count $SEL)" -lt 3 ]; then
  bad "fewer than 3 catalog-web pods are Ready after the rollout"
  exit 1
fi
exit 0
exit 1
