#!/bin/bash
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
k() { kubectl -n "$NS" "$@"; }

rep=$(k get deploy log-compactor -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ "${rep:-0}" -ne 3 ]; then
  echo "❌ log-compactor must keep 3 replicas (found ${rep:-none})"
  exit 1
fi
pods=$(k get pods -l app=log-compactor -o json | jq '[.items[] | select(.metadata.deletionTimestamp==null) | select(.status.phase != "Failed")]')
ready=$(echo "$pods" | jq '[.[] | select(.status.phase=="Running" and any(.status.conditions[]?; .type=="Ready" and .status=="True"))] | length')
if [ "$(echo "$pods" | jq length)" -ne 3 ] || [ "$ready" -ne 3 ]; then
  echo "❌ log-compactor: $ready of 3 pods Running"
  exit 1
fi
echo "✅ log-compactor: 3 pods Running"

# the kubelet checks ephemeral-storage usage periodically: pods must have outlived several checks
now=$(date +%s)
young=$(echo "$pods" | jq --argjson now "$now" '[.[] | select(($now - (.status.startTime | fromdateiso8601)) < 45)] | length')
if [ "$young" -ne 0 ]; then
  echo "❌ $young pod(s) started less than 45s ago; still waiting to see whether they survive"
  exit 1
fi

for p in $(echo "$pods" | jq -r '.[].metadata.name'); do
  size=$(k exec "$p" -- sh -c 'stat -c %s /work/compacted.bin' 2>/dev/null)
  if [ "${size:-0}" -lt 125000000 ]; then
    echo "❌ $p has not written its full compaction output (${size:-0} bytes)"
    exit 1
  fi
  lim=$(k get pod "$p" -o jsonpath='{.spec.containers[0].resources.limits.ephemeral-storage}')
  if [ -n "$lim" ] && [ "$(mem_to_mi "$lim")" -lt 125 ]; then
    echo "❌ $p: ephemeral-storage limit ${lim} is below what the compaction writes"
    exit 1
  fi
  rc=$(k get pod "$p" -o jsonpath='{.status.containerStatuses[0].restartCount}')
  if [ "${rc:-1}" -ne 0 ]; then
    echo "❌ $p restarted $rc time(s)"
    exit 1
  fi
done
echo "✅ every pod wrote its output and survived (limit: ${lim:-none})"
exit 0
exit 1
