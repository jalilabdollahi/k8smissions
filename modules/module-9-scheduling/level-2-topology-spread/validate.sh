#!/bin/bash
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
k() { kubectl -n "$NS" "$@"; }

ready=$(k get deploy catalog-api -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -ne 6 ]; then
  echo "❌ catalog-api: ${ready:-0} of 6 replicas Ready"
  exit 1
fi
pods=$(k get pods -l app.kubernetes.io/name=catalog-api -o json | jq '[.items[] | select(.metadata.deletionTimestamp==null)]')
if [ "$(echo "$pods" | jq length)" -ne 6 ]; then
  echo "❌ catalog-api: rollout still in progress ($(echo "$pods" | jq length) live pods)"
  exit 1
fi
echo "✅ catalog-api: 6 replicas Ready"

a=$(worker_n 1); b=$(worker_n 2)
ca=$(echo "$pods" | jq --arg n "$a" '[.[] | select(.spec.nodeName==$n)] | length')
cb=$(echo "$pods" | jq --arg n "$b" '[.[] | select(.spec.nodeName==$n)] | length')
if [ $((ca + cb)) -ne 6 ]; then
  echo "❌ catalog-api: only $((ca + cb)) of 6 pods run on the two workers (none may run on the control plane)"
  exit 1
fi
diff=$((ca - cb)); [ $diff -lt 0 ] && diff=$((-diff))
if [ $diff -gt 1 ]; then
  echo "❌ catalog-api is split $ca / $cb between the workers"
  exit 1
fi
echo "✅ catalog-api is split $ca / $cb between the workers"

# the constraint must still exist and must select the Deployment's own pods
ok=$(k get deploy catalog-api -o json | jq '
  .spec.template as $t
  | ($t.spec.topologySpreadConstraints // [])
  | any(.labelSelector != null
        and ((.labelSelector.matchLabels // {}) | to_entries | all(. as $e | $t.metadata.labels[$e.key] == $e.value))
        and ((.labelSelector.matchLabels // {}) != {} or (.labelSelector.matchExpressions // []) != []))')
if [ "$ok" != "true" ]; then
  echo "❌ catalog-api has no spread constraint that applies to its own pods"
  exit 1
fi
echo "✅ the spread constraint applies to catalog-api's own pods"
exit 0
exit 1
