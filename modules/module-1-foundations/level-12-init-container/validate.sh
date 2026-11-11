#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

dbready=$(k get deploy ledger-db -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
eps=$(k get endpointslices -l kubernetes.io/service-name=ledger-db -o jsonpath='{range .items[*].endpoints[?(@.conditions.ready==true)]}{.addresses[0]}{"\n"}{end}' 2>/dev/null | grep -c .)
if [ "${dbready:-0}" -lt 1 ] || [ "$eps" -lt 1 ]; then
  echo "❌ Service ledger-db has no Ready backend"
  exit 1
fi
echo "✅ Service ledger-db has $eps Ready backend(s)"

webready=$(k get deploy ledger-web -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${webready:-0}" -lt 1 ]; then
  echo "❌ Deployment ledger-web: no Ready pod"
  exit 1
fi
if ! k get deploy ledger-web -o jsonpath='{.spec.template.spec.initContainers[*].name}' | grep -qw wait-for-db; then
  echo "❌ the wait-for-db init container is gone from ledger-web"
  exit 1
fi
echo "✅ ledger-web is Ready and still has its wait-for-db init container"

out=$(k exec probe -- sh -c 'for i in 1 2 3 4 5; do curl -s --max-time 3 http://ledger-web; done' 2>/dev/null)
if [ "$(echo "$out" | grep -c 'db: reachable')" -ne 5 ]; then
  echo "❌ only $(echo "$out" | grep -c 'db: reachable') of 5 requests to ledger-web reported db: reachable"
  exit 1
fi
echo "✅ ledger-web reports db: reachable on 5 of 5 requests"
exit 0
exit 1
