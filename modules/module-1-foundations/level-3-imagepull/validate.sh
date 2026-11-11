#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

avail=$(k get deploy storefront -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ "${avail:-0}" -ne 2 ]; then
  echo "❌ storefront: ${avail:-0} of 2 replicas available"
  k get pods -l app=storefront --no-headers 2>/dev/null | awk '{print "   " $1 " " $3}'
  exit 1
fi
echo "✅ storefront has 2 available replicas"

img=$(k get deploy storefront -o jsonpath='{.spec.template.spec.containers[0].image}')
case "$img" in
  nginx:*) ;;
  *) echo "❌ storefront should keep running nginx (image is $img)"; exit 1 ;;
esac
bad=$(k get pods -l app=storefront -o jsonpath='{range .items[*]}{.status.containerStatuses[0].restartCount}{"\n"}{end}' | grep -vc '^0$')
if [ "$bad" != "0" ]; then
  echo "❌ some storefront pods have restarted"
  exit 1
fi
echo "✅ storefront pods run $img without restarts"

if [ "$(k get deploy storefront-canary -o jsonpath='{.spec.template.spec.containers[0].image}')" != "nginx:1.27-alpine" ] \
   || [ "$(k get deploy storefront-canary -o jsonpath='{.spec.replicas}')" != "1" ]; then
  echo "❌ storefront-canary was changed; leave it alone"
  exit 1
fi
echo "✅ storefront-canary untouched"

out=$(k exec probe -- sh -c 'for i in 1 2 3 4 5 6; do curl -s --max-time 3 http://storefront; done' 2>/dev/null)
if [ "$(echo "$out" | grep -c 'Acme storefront')" -ne 6 ]; then
  echo "❌ Service storefront did not answer 6 of 6 requests"
  exit 1
fi
echo "✅ Service storefront answers with the storefront page"
exit 0
exit 1
