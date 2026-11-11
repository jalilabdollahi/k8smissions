#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get svc shop >/dev/null 2>&1; then
  echo "❌ Service shop does not exist"
  exit 1
fi

blue=$(k get deploy shop-blue -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${blue:-0}" -ne 3 ]; then
  echo "❌ Deployment shop-blue: ${blue:-0} of 3 pods Ready, there is no way back"
  exit 1
fi
echo "✅ shop-blue is still up with 3 Ready pods"

green=$(k get deploy shop-green -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${green:-0}" -ne 3 ]; then
  echo "❌ Deployment shop-green: ${green:-0} of 3 pods Ready"
  exit 1
fi

gips=$(k get pods -l app=shop,release=green --field-selector=status.phase=Running -o jsonpath='{.items[*].status.podIP}' | tr ' ' '\n' | sort | tr '\n' ' ')
eps=$(k get endpointslices -l kubernetes.io/service-name=shop -o jsonpath='{range .items[*].endpoints[*]}{.addresses[0]}{"\n"}{end}' 2>/dev/null | sort | tr '\n' ' ')
if [ "$gips" != "$eps" ]; then
  echo "❌ Service shop sends traffic to [${eps:-nothing}], the green pods are [$gips]"
  exit 1
fi
echo "✅ Service shop's endpoints are exactly the green pods"

out=$(k exec probe -- sh -c 'for i in $(seq 30); do curl -s --max-time 2 http://shop; echo; done' 2>/dev/null)
good=$(echo "$out" | grep -c '^shop v2 (green)$')
if [ "$good" -ne 30 ]; then
  echo "❌ shop: only $good of 30 requests returned the green page"
  exit 1
fi
echo "✅ shop: 30 of 30 requests returned the green page"
exit 0
exit 1
