#!/bin/bash
# Level 5: all replicas Ready, then a real rolling restart must not make session-db reject anyone.
. ../_fixtures/lib.sh

for d in cart-api session-db; do
  if ! kubectl get deployment "$d" -n "$NS" >/dev/null 2>&1; then
    bad "Deployment $d does not exist"
    exit 1
  fi
done
want=$(kubectl get deployment cart-api -n "$NS" -o jsonpath='{.spec.replicas}')
if [ "${want:-0}" -lt 6 ]; then
  bad "cart-api is set to ${want:-0} replicas, it must keep 6"
  exit 1
fi
if ! wait_ready app=session-db 1 30; then
  bad "session-db is not Ready"
  exit 1
fi

stats() {
  kubectl exec -n "$NS" deploy/session-db -- python -c \
    "import urllib.request as u;print(u.urlopen('http://127.0.0.1:8081/',timeout=4).read().decode())" 2>/dev/null
}
MAXC=$(stats | jq -r '.max // 0')
if [ "$MAXC" -ne 20 ]; then
  bad "session-db must keep its limit of 20 connections (it reports $MAXC)"
  exit 1
fi

if ! wait_ready app=cart-api 6 45; then
  bad "only $(ready_count app=cart-api) of 6 cart-api pods are Ready, session-db reports $(stats | jq -r '.active') of 20 connections in use"
  exit 1
fi
ok "6 cart-api pods are Ready (session-db: $(stats | jq -r '.active') of 20 connections in use)"

R0=$(stats | jq -r '.rejected')
sleep 6
R1=$(stats | jq -r '.rejected')
if [ "$R1" != "$R0" ]; then
  bad "session-db is still rejecting connections in steady state"
  exit 1
fi

kubectl rollout restart deployment/cart-api -n "$NS" >/dev/null 2>&1
if ! kubectl rollout status deployment/cart-api -n "$NS" --timeout=60s >/dev/null 2>&1; then
  bad "the rolling restart of cart-api did not finish within 60s"
  exit 1
fi
R2=$(stats | jq -r '.rejected')
if [ "$R2" != "$R1" ]; then
  bad "session-db rejected $((R2 - R1)) connections during the rolling restart"
  exit 1
fi
ok "rolling restart finished and session-db rejected 0 connections"

OUT=$(run_probe "http://cart-api/" 8 2 10)
errs=$(echo "$OUT" | jq -r '.errors // "x"'); cnt=$(echo "$OUT" | jq -r '.count // 0')
if [ "$errs" != 0 ] || [ "$cnt" -lt 40 ]; then
  bad "Service cart-api returned errors after the restart (count=$cnt errors=$errs)"
  exit 1
fi
ok "Service cart-api answered $cnt requests with 0 errors"
exit 0
exit 1
