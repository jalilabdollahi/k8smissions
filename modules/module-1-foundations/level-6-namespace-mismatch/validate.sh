#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if [ "$(k get deploy orders-web -o jsonpath='{.status.readyReplicas}' 2>/dev/null)" != "1" ]; then
  echo "❌ Deployment orders-web is not Ready"
  exit 1
fi
echo "✅ orders-web is Ready"

api=""
for ns in "$NS" orders-staging; do
  r=$(kubectl -n "$ns" get deploy orders-api -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
  if [ "${r:-0}" -ge 1 ]; then api="$ns"; break; fi
done
if [ -z "$api" ]; then
  echo "❌ no ready orders-api Deployment found"
  exit 1
fi
echo "✅ a ready orders-api backend runs in namespace $api"

out=$(k exec probe -- sh -c 'for i in 1 2 3 4 5; do curl -s --max-time 4 -w "HTTP %{http_code}\n" http://orders-web; done' 2>/dev/null)
if [ "$(echo "$out" | grep -c '42 open orders')" -ne 5 ] || [ "$(echo "$out" | grep -c '^HTTP 200$')" -ne 5 ]; then
  echo "❌ Service orders-web did not return the orders payload 5 times out of 5"
  echo "$out" | head -2 | sed 's/^/   /'
  exit 1
fi
echo "✅ Service orders-web returns the orders-api payload"
exit 0
exit 1
