#!/bin/bash
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
CTRL=http://ingress-nginx-controller.ingress-nginx.svc
fail=0
ensure_probe || { bad "could not start the probe pod"; exit 1; }

phase=$(kubectl -n "$NS" get pvc shop-data -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$phase" = Bound ]; then ok "PVC shop-data is Bound"; else bad "PVC shop-data is ${phase:-missing}, not Bound"; fail=1; fi

if kubectl -n "$NS" wait --for=condition=complete job/db-migrate --timeout=5s >/dev/null 2>&1; then ok "Job db-migrate completed"; else bad "Job db-migrate has not completed"; fail=1; fi

want=$(kubectl -n "$NS" get deploy shop-web -o jsonpath='{.spec.replicas}' 2>/dev/null)
n=$(ready_count app=shop-web)
if [ "${want:-0}" -ge 2 ] && [ "${n:-0}" -ge "$want" ]; then ok "shop-web: $n of $want pods Ready"; else bad "shop-web: ${n:-0} of ${want:-?} pods Ready (need 2)"; fail=1; fi

host=$(kubectl -n "$NS" get ingress shop -o jsonpath='{.spec.rules[0].host}' 2>/dev/null)
[ "$host" = shop.local ] || { bad "Ingress shop must keep host shop.local"; fail=1; }

[ "$fail" = 0 ] || exit 1
body=""
for i in $(seq 1 10); do
  body=$(pcurl -H 'Host: shop.local' "$CTRL/")
  echo "$body" | grep -q 'database schema v7' && break
  sleep 2
done
if echo "$body" | grep -q 'Winter Sale is open. database schema v7, served by shop-web-'; then
  ok "http://shop.local/ through the ingress returns the shop page"
  exit 0
fi
bad "http://shop.local/ through the ingress returned: ${body:-no answer or an error page}"
exit 1
