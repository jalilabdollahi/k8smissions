#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

ready=$(k get deploy rates-sync -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -ne 2 ]; then
  echo "❌ Deployment rates-sync: ${ready:-0} of 2 pods Ready"
  exit 1
fi
if ! k get deploy rates-sync -o jsonpath='{.spec.template.spec.volumes[*].configMap.name}' | grep -qw rates-sync-conf; then
  echo "❌ rates-sync no longer reads its configuration from ConfigMap rates-sync-conf"
  exit 1
fi
echo "✅ rates-sync has 2 Ready pods reading ConfigMap rates-sync-conf"

sleep 20
bad=$(k get pods -l app=rates-sync -o json | python3 -c '
import json,sys
n=0
for p in json.load(sys.stdin)["items"]:
    if p["metadata"].get("deletionTimestamp"): continue
    cs=p["status"].get("containerStatuses",[])
    if not cs or not cs[0]["ready"] or cs[0]["restartCount"]>0: n+=1
print(n)')
if [ "$bad" != "0" ]; then
  echo "❌ $bad rates-sync pod(s) restarted or are not Ready after 20s"
  exit 1
fi
echo "✅ rates-sync stayed up for 20s"

for p in $(k get pods -l app=rates-sync -o name); do
  if ! k logs "$p" 2>/dev/null | grep -q 'rates loaded: 2 regions'; then
    echo "❌ $p did not log 'rates loaded: 2 regions'"
    exit 1
  fi
done
echo "✅ every pod loaded 2 regions"

out=$(k exec probe -- sh -c 'for i in 1 2 3 4; do curl -s --max-time 3 http://rates-sync; done' 2>/dev/null)
if [ "$(echo "$out" | grep -c '"EURUSD"')" -ne 4 ]; then
  echo "❌ Service rates-sync did not return the rates JSON 4 times out of 4"
  exit 1
fi
echo "✅ Service rates-sync returns the rates JSON"
exit 0
exit 1
