#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

ready=$(k get deploy storefront -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -ne 2 ]; then
  echo "❌ Deployment storefront: ${ready:-0} of 2 pods Ready"
  exit 1
fi
echo "✅ storefront has 2 Ready pods"

if ! k get svc storefront-lb >/dev/null 2>&1; then
  echo "❌ Service storefront-lb does not exist"
  exit 1
fi
lb=$(k get svc -o jsonpath='{range .items[?(@.spec.type=="LoadBalancer")]}{.metadata.name}{" "}{end}')
if [ -n "$lb" ]; then
  echo "❌ LoadBalancer Services still in the namespace: $lb"
  exit 1
fi
echo "✅ no LoadBalancer Service is left pending"

port=$(k get svc storefront-lb -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
if [ -z "$port" ]; then
  echo "❌ storefront-lb publishes no node port, so nothing outside the pod network can reach it"
  exit 1
fi

ips=$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{range .items[*]}{.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}')
[ -n "$ips" ] || { echo "❌ no worker nodes found"; exit 1; }
for ip in $ips; do
  body=$(k exec probe -- curl -s --max-time 4 "http://$ip:$port/" 2>/dev/null)
  if [ "$body" != "storefront: partner portal" ]; then
    echo "❌ http://$ip:$port/ did not return the storefront (got: '${body:-no answer}')"
    exit 1
  fi
  echo "✅ http://$ip:$port/ returns the storefront"
done
exit 0
exit 1
