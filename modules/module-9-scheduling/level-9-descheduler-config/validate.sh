#!/bin/bash
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
k() { kubectl -n "$NS" "$@"; }

if ! k get cronjob descheduler >/dev/null 2>&1 || ! k get configmap descheduler-policy >/dev/null 2>&1; then
  echo "❌ CronJob descheduler and ConfigMap descheduler-policy must stay in place"
  exit 1
fi
rep=$(k get deploy search-indexer -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ "${rep:-0}" -ne 8 ]; then
  echo "❌ Deployment search-indexer must keep its 8 replicas (found ${rep:-none})"
  exit 1
fi

# a descheduler Job that completed and logged evictions
found=""
for j in $(k get jobs -o json | jq -r '.items[] | select((.status.succeeded // 0) >= 1) | .metadata.name'); do
  if k logs "job/$j" 2>/dev/null | grep -q 'Evicted pod'; then found=$j; break; fi
done
if [ -z "$found" ]; then
  failed=$(k get jobs -o json | jq '[.items[] | select((.status.failed // 0) >= 1)] | length')
  done_n=$(k get jobs -o json | jq '[.items[] | select((.status.succeeded // 0) >= 1)] | length')
  echo "❌ no Descheduler Job has completed with evictions yet (failed Jobs: $failed, completed without evictions: $done_n)"
  exit 1
fi
echo "✅ Job $found completed and evicted pods"

a=$(worker_n 1); b=$(worker_n 2)
pods=$(k get pods -l app=search-indexer -o json | jq '[.items[] | select(.metadata.deletionTimestamp==null)]')
running=$(echo "$pods" | jq '[.[] | select(.status.phase=="Running")] | length')
ca=$(echo "$pods" | jq --arg n "$a" '[.[] | select(.spec.nodeName==$n)] | length')
cb=$(echo "$pods" | jq --arg n "$b" '[.[] | select(.spec.nodeName==$n)] | length')
if [ "$running" -ne 8 ]; then
  echo "❌ search-indexer: $running of 8 pods Running"
  exit 1
fi
if [ "$ca" -lt 3 ] || [ "$cb" -lt 3 ]; then
  echo "❌ search-indexer is split $ca / $cb over the workers (at least 3 on each expected)"
  exit 1
fi
echo "✅ search-indexer: 8 pods Running, split $ca / $cb"
exit 0
exit 1
