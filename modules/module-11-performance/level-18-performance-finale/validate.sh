#!/bin/bash
# Level 18 (finale): one load run through the whole path, then each layer is checked on its own evidence.
. ../_fixtures/lib.sh

for d in storefront pricing catalog-dns; do
  if ! kubectl get deployment "$d" -n "$NS" >/dev/null 2>&1; then
    bad "Deployment $d does not exist"
    exit 1
  fi
done
want=$(kubectl get deployment pricing -n "$NS" -o jsonpath='{.spec.replicas}')
if [ "${want:-0}" -lt 3 ]; then
  bad "pricing must keep 3 replicas (it has ${want:-0})"
  exit 1
fi
if ! wait_ready app=pricing 3 60 || ! wait_ready app=storefront 1 40 || ! wait_ready app=catalog-dns 1 40; then
  bad "pricing $(ready_count app=pricing)/3, storefront $(ready_count app=storefront)/1 or catalog-dns not Ready"
  exit 1
fi
PRICING=$(live_pods app=pricing)
SF=$(live_pods app=storefront | head -1)

py() { kubectl exec -n "$NS" "$1" -c "$2" -- python -c "$3" 2>/dev/null; }
STAT="import urllib.request;print(urllib.request.urlopen('http://127.0.0.1:8080/stats',timeout=4).read().decode())"
counts() { for p in $PRICING; do py "$p" pricing "$STAT" | jq -r '.requests // 0'; done | paste -sd' ' -; }
calls() { py "$SF" storefront "$STAT" | jq -r '.calls // 0'; }
throttle() {
  local P=0 T=0 p np nt
  for p in $PRICING; do read -r np nt _ <<<"$(cgroup_cpu "$p" pricing)"; P=$((P + np)); T=$((T + nt)); done
  echo "$P $T"
}

C0=$(counts); S0=$(calls); read -r P0 T0 <<<"$(throttle)"
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
OUT=$(run_probe "http://storefront/page" 30 8 30 TIMEOUT=3)
C1=$(counts); S1=$(calls); read -r P1 T1 <<<"$(throttle)"
DNSQ=$(kubectl logs -n "$NS" deploy/catalog-dns --since-time="$TS" 2>/dev/null | grep -c '"A IN')

cnt=$(echo "$OUT" | jq -r '.count // 0'); errs=$(echo "$OUT" | jq -r '.errors // 999'); p95=$(echo "$OUT" | jq -r '.p95_ms // 99999')
if [ "$cnt" -lt 300 ]; then
  bad "the page probe completed only $cnt of about 900 requests in 30s"
  exit 1
fi
FAIL=0
if [ "$errs" -ne 0 ]; then
  bad "$errs of $cnt page requests failed or timed out"
  FAIL=1
fi
if [ "$p95" -ge 300 ]; then
  bad "end-to-end p95 is ${p95}ms (goal 300ms)"
  FAIL=1
else
  ok "end-to-end p95 is ${p95}ms with $cnt requests"
fi

# DNS: queries per lookup, counted at the resolver
DC=$((S1 - S0))
if [ "$DC" -lt 100 ]; then
  bad "storefront served only $DC lookups during the test"
  exit 1
fi
if [ $((DNSQ * 10)) -gt $((DC * 15)) ]; then
  bad "the resolver logged $DNSQ queries for $DC lookups (about $((DNSQ / DC)) per lookup)"
  FAIL=1
else
  ok "the resolver logged $DNSQ queries for $DC lookups"
fi

# CPU throttling on pricing
DP=$((P1 - P0)); DT=$((T1 - T0))
if [ "$DP" -gt 0 ] && [ $((DT * 100)) -gt $((DP * 10)) ]; then
  bad "pricing was throttled in $DT of $DP CPU periods"
  FAIL=1
else
  ok "pricing throttled in $DT of ${DP:-0} CPU periods"
fi

# fair share between the pricing pods
read -ra A <<<"$C0"; read -ra B <<<"$C1"
MIN=999999999; MAX=0; i=0; SUM=0
while [ $i -lt ${#A[@]} ]; do
  d=$((B[i] - A[i])); [ "$d" -lt 0 ] && d=0
  [ "$d" -lt "$MIN" ] && MIN=$d
  [ "$d" -gt "$MAX" ] && MAX=$d
  SUM=$((SUM + d)); i=$((i + 1))
done
if [ ${#A[@]} -lt 3 ] || [ "$MIN" -eq 0 ] || [ "$MAX" -gt $((MIN * 2)) ]; then
  bad "requests per pricing pod during the test: ${B[*]} minus ${A[*]} (busiest ${MAX}, quietest ${MIN})"
  FAIL=1
else
  ok "requests were shared across the 3 pricing pods (busiest $MAX, quietest $MIN)"
fi
[ "$FAIL" = 0 ] && exit 0
exit 1
