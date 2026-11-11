#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

ready=$(k get deploy thumbnailer -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -ne 2 ]; then
  echo "❌ Deployment thumbnailer: ${ready:-0} of 2 pods Ready"
  exit 1
fi
limit=$(k get deploy thumbnailer -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}')
if [ -z "$limit" ]; then
  echo "❌ thumbnailer has no memory limit any more; the namespace policy requires one"
  exit 1
fi
echo "✅ thumbnailer has 2 Ready pods and a memory limit ($limit)"

sleep 30
bad=$(k get pods -l app=thumbnailer -o json | python3 -c '
import json,sys
n=0
for p in json.load(sys.stdin)["items"]:
    if p["metadata"].get("deletionTimestamp"): continue
    cs=p["status"].get("containerStatuses",[])
    if not cs or not cs[0]["ready"] or cs[0]["restartCount"]>0: n+=1
print(n)')
if [ "$bad" != "0" ]; then
  echo "❌ $bad thumbnailer pod(s) restarted or are not Ready after 30s"
  exit 1
fi
echo "✅ no restarts over a 30s window"

out=$(k exec probe -- sh -c 'for i in 1 2 3 4 5 6; do curl -s --max-time 3 http://thumbnailer; done' 2>/dev/null)
if [ "$(echo "$out" | grep -c 'thumbnailer cache ready')" -ne 6 ]; then
  echo "❌ only $(echo "$out" | grep -c 'thumbnailer cache ready') of 6 requests returned the cache-ready page"
  exit 1
fi
echo "✅ Service thumbnailer answers 6 of 6 requests"
exit 0
exit 1
