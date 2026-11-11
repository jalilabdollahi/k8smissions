#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

ready=$(k get deploy rates-proxy -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -ne 2 ]; then
  echo "❌ Deployment rates-proxy: ${ready:-0} of 2 pods Ready"
  exit 1
fi
if ! k get deploy rates-proxy -o jsonpath='{.spec.template.spec.containers[*].name}' | grep -qw edge; then
  echo "❌ the edge container is gone from the pod template"
  exit 1
fi
echo "✅ Deployment rates-proxy has 2 Ready pods with the edge container"

sleep 20
pods=$(k get pods -l app=rates-proxy --field-selector=status.phase=Running -o json 2>/dev/null)
bad=$(echo "$pods" | python3 -c '
import json,sys
n=0
for p in json.load(sys.stdin)["items"]:
    if p["metadata"].get("deletionTimestamp"): continue
    cs=p["status"].get("containerStatuses",[])
    if len(cs)<2 or any((not c["ready"]) or c["restartCount"]>0 for c in cs): n+=1
print(n)')
if [ "$bad" != "0" ]; then
  echo "❌ $bad pod(s) have a container that is not Ready or has restarted"
  exit 1
fi
echo "✅ Every container stayed up for 20s"

out=$(k exec probe -- sh -c 'for i in 1 2 3 4 5 6; do curl -si --max-time 3 http://rates-proxy; done' 2>/dev/null)
if [ "$(echo "$out" | grep -c 'rates: EUR/USD 1.08')" -ne 6 ]; then
  echo "❌ Service rates-proxy did not return the rates page 6 times out of 6"
  exit 1
fi
if [ "$(echo "$out" | grep -ci '^x-edge: rates-proxy')" -ne 6 ]; then
  echo "❌ answers are not passing through the edge proxy"
  exit 1
fi
echo "✅ Service rates-proxy returns the rates page through edge"
exit 0
exit 1
