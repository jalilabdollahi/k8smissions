#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

ready=$(k get deploy status-page -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -ne 3 ]; then
  echo "❌ Deployment status-page: ${ready:-0} of 3 pods Ready"
  exit 1
fi
type=$(k get svc status-page -o jsonpath='{.spec.type}' 2>/dev/null)
if [ "$type" != "NodePort" ]; then
  echo "❌ Service status-page is type '${type:-missing}', expected NodePort"
  exit 1
fi
echo "✅ status-page: 3 pods Ready behind a NodePort Service"

ips=$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{range .items[*]}{.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}')
[ -n "$ips" ] || { echo "❌ no worker nodes found"; exit 1; }
for ip in $ips; do
  body=$(k exec probe -- curl -s --max-time 4 "http://$ip:30080/" 2>/dev/null)
  if [ "$body" != "status: all systems operational" ]; then
    echo "❌ http://$ip:30080/ did not return the status page (got: '${body:-no answer}')"
    exit 1
  fi
  echo "✅ http://$ip:30080/ returns the status page"
done
exit 0
exit 1
