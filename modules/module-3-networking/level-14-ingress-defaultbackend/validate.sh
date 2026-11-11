#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }
CTRL=http://ingress-nginx-controller.ingress-nginx.svc

for s in docs maintenance; do
  n=$(k get endpointslices -l kubernetes.io/service-name=$s -o jsonpath='{range .items[*].endpoints[?(@.conditions.ready==true)]}{.addresses[0]}{"\n"}{end}' 2>/dev/null | grep -c .)
  if [ "$n" -lt 1 ]; then
    echo "❌ Service $s has no ready endpoints"
    exit 1
  fi
done
if ! k get ingress docs >/dev/null 2>&1; then
  echo "❌ Ingress docs does not exist"
  exit 1
fi
echo "✅ docs and maintenance have ready endpoints, Ingress docs exists"

body=$(k exec probe -- curl -s --max-time 5 -H 'Host: docs.k8sm.local' "$CTRL/" 2>/dev/null)
if [ "$body" != "docs: engineering handbook" ]; then
  echo "❌ Host docs.k8sm.local returned '${body:-no answer}'"
  exit 1
fi
echo "✅ docs.k8sm.local serves the handbook"

body=$(k exec probe -- curl -s --max-time 5 -H 'Host: nobody.k8sm.local' "$CTRL/anything" 2>/dev/null)
if [ "$body" != "maintenance: we are back soon" ]; then
  echo "❌ an unknown host returned '${body:-no answer}', not the maintenance page"
  exit 1
fi
echo "✅ unknown hosts get the maintenance page"
exit 0
exit 1
