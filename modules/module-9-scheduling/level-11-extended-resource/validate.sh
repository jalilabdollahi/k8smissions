#!/bin/bash
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
k() { kubectl -n "$NS" "$@"; }

res=$(k get configmap fpga-inventory -o jsonpath='{.data.resource}' 2>/dev/null)
if [ -z "$res" ]; then
  echo "❌ ConfigMap fpga-inventory is missing"
  exit 1
fi
# the inventory must still be what the nodes advertise (the card count is not something to edit)
for n in $(workers); do
  want=$(k get configmap fpga-inventory -o jsonpath="{.data.$n}")
  have=$(kubectl get node "$n" -o json | jq -r --arg r "$res" '.status.capacity[$r] // "0"')
  if [ "$want" != "$have" ]; then
    echo "❌ node $n advertises $have of $res but the inventory says $want"
    exit 1
  fi
done

rep=$(k get deploy video-transcode -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ "${rep:-0}" -ne 3 ]; then
  echo "❌ video-transcode must keep 3 replicas (found ${rep:-none})"
  exit 1
fi
pods=$(k get pods -l app=video-transcode -o json | jq '[.items[] | select(.metadata.deletionTimestamp==null)]')
running=$(echo "$pods" | jq '[.[] | select(.status.phase=="Running" and any(.status.conditions[]?; .type=="Ready" and .status=="True"))] | length')
if [ "$running" -ne 3 ]; then
  echo "❌ video-transcode: $running of 3 pods Running"
  exit 1
fi
echo "✅ video-transcode: 3 pods Running"

bad=$(echo "$pods" | jq --arg r "$res" '[.[] | .spec.containers[] | select((.resources.requests[$r] // "0") != "1" or (.resources.limits[$r] // "0") != "1")] | length')
if [ "$bad" -ne 0 ]; then
  echo "❌ every transcoder container must hold exactly one $res (request equal to limit)"
  exit 1
fi
echo "✅ each pod requests and is limited to one $res"

for n in $(workers); do
  cnt=$(echo "$pods" | jq --arg n "$n" '[.[] | select(.spec.nodeName==$n)] | length')
  have=$(kubectl get node "$n" -o json | jq -r --arg r "$res" '.status.capacity[$r] // "0"')
  if [ "$cnt" -gt "$have" ]; then
    echo "❌ node $n runs $cnt transcoders but advertises only $have cards"
    exit 1
  fi
  echo "✅ node $n: $cnt pods on $have cards"
done
if [ "$(echo "$pods" | jq '[.[] | select(.spec.nodeName != null)] | length')" -ne 3 ]; then
  echo "❌ not every pod is scheduled"
  exit 1
fi
exit 0
exit 1
