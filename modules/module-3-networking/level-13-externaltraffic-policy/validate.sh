#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

ready=$(k get deploy audit-gw -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -lt 2 ]; then
  echo "❌ Deployment audit-gw: ${ready:-0} of 2 pods Ready"
  exit 1
fi
echo "✅ audit-gw has ${ready} Ready pods"

pol=$(k get svc audit-gw -o jsonpath='{.spec.type} {.spec.externalTrafficPolicy}' 2>/dev/null)
if [ "$pol" != "NodePort Local" ]; then
  echo "❌ Service audit-gw is '${pol:-missing}', it must stay a NodePort with externalTrafficPolicy Local"
  exit 1
fi
echo "✅ audit-gw keeps externalTrafficPolicy: Local"

port=$(k get svc audit-gw -o jsonpath='{.spec.ports[0].nodePort}')
me=$(k get pod gw-client -o jsonpath='{.status.hostIP}' 2>/dev/null)
if [ -z "$me" ] || [ -z "$port" ]; then
  echo "❌ gw-client or the node port is missing"
  exit 1
fi
ips=$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{range .items[*]}{.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}')
for ip in $ips; do
  for i in 1 2 3; do
    body=$(k exec gw-client -- curl -s --max-time 4 "http://$ip:$port/" 2>/dev/null)
    if [ -z "$body" ]; then
      echo "❌ http://$ip:$port/ gave no answer"
      exit 1
    fi
    if [ "$body" != "caller=$me" ]; then
      echo "❌ http://$ip:$port/ answered but saw the caller as '${body#caller=}', expected $me"
      exit 1
    fi
  done
  echo "✅ http://$ip:$port/ answers and keeps the caller address $me"
done
exit 0
exit 1
