#!/bin/bash
# Level 15: real lookups from a price-feed pod (so the policy applies), and a probe of a destination that must stay blocked.
. ../_fixtures/lib.sh
SEL=app=price-feed

for d in price-feed catalog-dns ledger-sink; do
  if ! kubectl get deployment "$d" -n "$NS" >/dev/null 2>&1; then
    bad "Deployment $d does not exist"
    exit 1
  fi
done
if ! wait_ready app=catalog-dns 1 40 || ! wait_ready app=ledger-sink 1 40 || ! wait_ready "$SEL" 2 40; then
  bad "price-feed, catalog-dns or ledger-sink has pods that are not Ready"
  exit 1
fi
POD=$(live_pods "$SEL" | head -1)
SINK=$(kubectl get pod -n "$NS" -l app=ledger-sink -o jsonpath='{.items[0].status.podIP}')

OUT=$(kubectl exec -n "$NS" "$POD" -- python -c "
import socket, time
def look(name):
    t = time.time()
    try:
        n = len({a[4][0] for a in socket.getaddrinfo(name, None, socket.AF_INET)})
    except Exception:
        n = -1
    return n, int((time.time() - t) * 1000)
small = [look('quotes.catalog.internal.'), look('currency.catalog.internal.')]
print('small', ' '.join('%d/%d' % r for r in small))
slow = 0; fails = 0; worst = 0; addrs = 0
for _ in range(10):
    n, ms = look('sku-history.catalog.internal.')
    worst = max(worst, ms); addrs = max(addrs, n)
    if n < 1: fails += 1
    if ms >= 500: slow += 1
    if ms >= 2000: break
print('big', fails, slow, worst, addrs)
s = socket.socket(); s.settimeout(3)
try:
    s.connect(('$SINK', 8080)); print('sink open')
except Exception:
    print('sink blocked')
" 2>/dev/null)
small=$(echo "$OUT" | awk '$1=="small"{print $2, $3}')
read -r fails slow worst addrs <<<"$(echo "$OUT" | awk '$1=="big"{print $2, $3, $4, $5}')"
if [ -z "$fails" ]; then
  bad "the test could not run inside $POD"
  exit 1
fi
for r in $small; do
  if [ "${r%/*}" -lt 1 ]; then
    bad "a small name no longer resolves from price-feed ($small)"
    exit 1
  fi
done
ok "small names resolve ($small)"
if [ "$fails" -gt 0 ] || [ "$slow" -gt 0 ]; then
  bad "sku-history.catalog.internal: $fails failed and $slow slow (worst ${worst}ms) in the lookups"
  exit 1
fi
if [ "${addrs:-0}" -lt 40 ]; then
  bad "sku-history.catalog.internal returns only $addrs addresses: the answer must stay complete"
  exit 1
fi
ok "sku-history.catalog.internal: 10 of 10 lookups fast (worst ${worst}ms), $addrs addresses"
if ! echo "$OUT" | grep -q "sink blocked"; then
  bad "price-feed can now reach ledger-sink: the egress policy no longer restricts it"
  exit 1
fi
ok "price-feed still cannot reach ledger-sink"
exit 0
exit 1
