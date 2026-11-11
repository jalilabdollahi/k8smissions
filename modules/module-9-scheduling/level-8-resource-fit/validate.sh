#!/bin/bash
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
k() { kubectl -n "$NS" "$@"; }

rep=$(k get deploy video-encoder -o jsonpath='{.spec.replicas}' 2>/dev/null)
pods=$(k get pods -l app=video-encoder -o json | jq '[.items[] | select(.metadata.deletionTimestamp==null)]')
running=$(echo "$pods" | jq '[.[] | select(.status.phase=="Running")] | length')
if [ "${rep:-0}" -ne 3 ] || [ "$(echo "$pods" | jq length)" -ne 3 ] || [ "$running" -ne 3 ]; then
  echo "❌ video-encoder: $running Running of 3 required (replicas: ${rep:-none})"
  exit 1
fi
echo "✅ video-encoder: 3 of 3 replicas Running"

a=$(worker_n 1); b=$(worker_n 2)
ca=$(echo "$pods" | jq --arg n "$a" '[.[] | select(.spec.nodeName==$n)] | length')
cb=$(echo "$pods" | jq --arg n "$b" '[.[] | select(.spec.nodeName==$n)] | length')
if [ $((ca + cb)) -ne 3 ] || [ "$ca" -eq 0 ] || [ "$cb" -eq 0 ]; then
  echo "❌ replicas are split $ca / $cb over the workers (both must run some, none on the control plane)"
  exit 1
fi
echo "✅ replicas are split $ca / $cb over the workers"

orig=$(k get configmap encoder-capacity-plan -o jsonpath='{.data.original-cpu-request-m}' 2>/dev/null)
if [ -z "$orig" ]; then
  orig=$(( $(cpu_to_m "$(kubectl get node "$a" -o jsonpath='{.status.allocatable.cpu}')") / 4 ))
fi
floor=$(( orig * 4 / 10 ))
for q in $(echo "$pods" | jq -r '.[].spec.containers[].resources.requests.cpu // "0"'); do
  m=$(cpu_to_m "$q")
  if [ "$m" -lt "$floor" ]; then
    echo "❌ a replica requests ${q} of CPU, less than the 40% of the original (${orig}m) that the encoder needs to hold its frame rate"
    exit 1
  fi
done
echo "✅ every replica still requests a real share of CPU"
exit 0
exit 1
