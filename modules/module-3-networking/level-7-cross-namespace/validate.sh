#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

r=$(k get deploy storefront -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${r:-0}" -ne 2 ]; then
  echo "❌ Deployment storefront: ${r:-0} of 2 pods Ready"
  exit 1
fi
echo "✅ storefront has 2 Ready pods"

ips=$(k get pods -l app=storefront -o jsonpath='{range .items[*]}{.status.podIP} {.metadata.deletionTimestamp}{"\n"}{end}' | awk 'NF==1{print $1}')
for round in 1 2 3 4 5; do
  for ip in $ips; do
    st=$(k exec probe -- curl -s --max-time 5 "http://$ip:8080/" 2>/dev/null)
    if [ "$st" != "upstream: ok" ]; then
      echo "❌ storefront $ip reports '${st:-no answer}'"
      exit 1
    fi
  done
  sleep 2
done
echo "✅ storefront reports upstream: ok on every check"

np=$(kubectl -n warehouse get networkpolicy -o name 2>/dev/null | grep -c .)
if [ "$np" -lt 1 ]; then
  echo "❌ warehouse has no NetworkPolicy left; it must stay isolated"
  exit 1
fi
if kubectl -n contractors exec outsider -- curl -s --max-time 4 http://inventory.warehouse.svc.cluster.local:8080/ >/dev/null 2>&1; then
  echo "❌ the pod in namespace contractors can reach inventory"
  exit 1
fi
echo "✅ warehouse is still isolated from other namespaces"
exit 0
exit 1
