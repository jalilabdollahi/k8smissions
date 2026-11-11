#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

ready=$(k get deploy checkout -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -ne 2 ]; then
  echo "❌ Deployment checkout: ${ready:-0} of 2 pods Ready"
  exit 1
fi
names=$(k get deploy checkout -o jsonpath='{.spec.template.spec.containers[*].name}')
for c in nginx log-shipper; do
  if ! echo "$names" | grep -qw "$c"; then
    echo "❌ container $c is missing from the checkout pod template"
    exit 1
  fi
done
echo "✅ checkout has 2 Ready pods with nginx and log-shipper"

sleep 15
bad=$(k get pods -l app=checkout -o json | python3 -c '
import json,sys
n=0
for p in json.load(sys.stdin)["items"]:
    if p["metadata"].get("deletionTimestamp"): continue
    cs=p["status"].get("containerStatuses",[])
    if len(cs)<2 or any((not c["ready"]) or c["restartCount"]>0 for c in cs): n+=1
print(n)')
if [ "$bad" != "0" ]; then
  echo "❌ $bad checkout pod(s) have a container that is not Ready or has restarted"
  exit 1
fi
echo "✅ both containers stayed up for 15s"

tag=$RANDOM$RANDOM
for i in 1 2 3 4; do
  k exec probe -- curl -s -o /dev/null --max-time 3 "http://checkout/ping-$tag-$i" 2>/dev/null
done
sleep 3
logs=$(for p in $(k get pods -l app=checkout -o name); do k logs "$p" -c log-shipper 2>/dev/null; done)
found=0
for i in 1 2 3 4; do
  echo "$logs" | grep -q "ping-$tag-$i" && found=$((found+1))
done
if [ "$found" -ne 4 ]; then
  echo "❌ only $found of 4 requests to checkout appear in the log-shipper logs"
  exit 1
fi
echo "✅ all 4 requests are visible in the log-shipper logs"
exit 0
exit 1
