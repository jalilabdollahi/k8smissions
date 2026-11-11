#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }
CTRL=http://ingress-nginx-controller.ingress-nginx.svc

ready=$(k get deploy storefront -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -lt 1 ] || ! k get ingress shop >/dev/null 2>&1; then
  echo "❌ Ingress shop or the storefront backend is missing or not Ready"
  exit 1
fi
echo "✅ Ingress shop and the storefront backend exist"

home=$(k exec probe -- curl -s --max-time 5 -H 'Host: shop.k8sm.local' "$CTRL/shop" 2>/dev/null)
if [ "$home" != "storefront home" ]; then
  echo "❌ /shop did not return the storefront home page (got: '${home:-no answer}')"
  exit 1
fi
echo "✅ /shop reaches the storefront home page"

items=$(k exec probe -- curl -s --max-time 5 -H 'Host: shop.k8sm.local' "$CTRL/shop/items" 2>/dev/null)
if [ "$items" != "items: mug, poster, sticker" ]; then
  echo "❌ /shop/items did not return the items list (got: '${items:-no answer}')"
  exit 1
fi
echo "✅ /shop/items returns the items list"
exit 0
exit 1
