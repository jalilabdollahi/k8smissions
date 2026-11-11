#!/bin/bash
# Level 3: queries per lookup, counted in the dns-lab log, must drop to <= 1.5.
. ../_fixtures/lib.sh

for d in dns-lab rate-limiter; do
  if ! kubectl get deployment "$d" -n "$NS" >/dev/null 2>&1; then
    bad "Deployment $d does not exist"
    exit 1
  fi
done
if ! wait_ready app=rate-limiter 1 40 || ! wait_ready app=dns-lab 1 40; then
  bad "dns-lab and rate-limiter need a Ready pod each"
  exit 1
fi

# the window must belong to the current rate-limiter pod
POD=$(live_pods app=rate-limiter | head -1)
start=$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.status.startTime}')
age=$(( $(date +%s) - $(echo "$start" | jq -R 'fromdateiso8601') ))
if [ "$age" -lt 28 ]; then sleep $((28 - age)); fi

CL=$(kubectl logs -n "$NS" "$POD" --since=20s 2>/dev/null)
DNS=$(kubectl logs -n "$NS" deploy/dns-lab --since=20s 2>/dev/null)
LOOKUPS=$(echo "$CL" | jq -s '[.[]?.lookups] | add // 0' 2>/dev/null)
OKS=$(echo "$CL" | jq -s '[.[]?.ok] | add // 0' 2>/dev/null)
BAD=$(echo "$CL" | jq -s '[.[]? | .wrong + .fail] | add // 0' 2>/dev/null)
SHORTBAD=$(echo "$CL" | jq -s '[.[]?.short_fail] | add // 0' 2>/dev/null)
Q=$(echo "$DNS" | grep -c 'IN quotas.payments.internal')

if [ "${LOOKUPS:-0}" -lt 100 ]; then
  bad "rate-limiter logged only ${LOOKUPS:-0} lookups in 20s, it is not sending its normal traffic"
  exit 1
fi
if [ "${BAD:-1}" -ne 0 ] || [ "${OKS:-0}" -lt 100 ]; then
  bad "lookups of quotas.payments.internal are failing or returning the wrong address ($BAD bad of $LOOKUPS)"
  exit 1
fi
if [ "${SHORTBAD:-1}" -ne 0 ]; then
  bad "the short name session-cache stopped resolving ($SHORTBAD failures)"
  exit 1
fi
ok "$LOOKUPS lookups in 20s, all resolved to the right address; session-cache still resolves"

PER=$(awk -v q="$Q" -v l="$LOOKUPS" 'BEGIN{printf "%.2f", q/l}')
if awk -v p="$PER" 'BEGIN{exit !(p > 1.5)}'; then
  bad "dns-lab saw $Q queries for $LOOKUPS lookups ($PER per lookup), limit is 1.5"
  exit 1
fi
ok "dns-lab saw $Q queries for $LOOKUPS lookups ($PER per lookup)"
exit 0
exit 1
