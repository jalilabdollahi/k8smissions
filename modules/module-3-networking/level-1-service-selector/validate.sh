#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

ready=$(k get deploy cart -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -ne 3 ]; then
  echo "❌ Deployment cart: ${ready:-0} of 3 pods Ready"
  exit 1
fi
echo "✅ Deployment cart has 3 Ready pods"

web=$(k get pods -l app=cart,tier=web --field-selector=status.phase=Running -o jsonpath='{.items[*].status.podIP}' 2>/dev/null | tr ' ' '\n' | sort | tr '\n' ' ')
eps=$(k get endpointslices -l kubernetes.io/service-name=cart -o jsonpath='{range .items[*].endpoints[*]}{.addresses[0]}{"\n"}{end}' 2>/dev/null | sort | tr '\n' ' ')
if [ "$web" != "$eps" ]; then
  echo "❌ Service cart sends traffic to: [${eps:-nothing}] but the storefront pods are: [$web]"
  exit 1
fi
echo "✅ Service cart sends traffic to exactly the storefront pods"

out=$(k exec probe -- sh -c 'for i in $(seq 40); do curl -s --max-time 2 http://cart; echo; done' 2>/dev/null)
good=$(echo "$out" | grep -c '^storefront: cart page$')
if [ "$good" -ne 40 ]; then
  echo "❌ cart: only $good of 40 requests returned the cart page"
  exit 1
fi
echo "✅ cart: 40 of 40 requests returned the cart page"
exit 0
exit 1
