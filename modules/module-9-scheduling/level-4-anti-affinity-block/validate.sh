#!/bin/bash
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
k() { kubectl -n "$NS" "$@"; }

spec=$(k get deploy ledger-api -o jsonpath='{.spec.replicas}' 2>/dev/null)
ready=$(k get deploy ledger-api -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${spec:-0}" -ne 3 ] || [ "${ready:-0}" -ne 3 ]; then
  echo "❌ ledger-api: ${ready:-0} of ${spec:-0} replicas Ready (3 required)"
  exit 1
fi
pods=$(k get pods -l app=ledger-api -o json | jq '[.items[] | select(.metadata.deletionTimestamp==null)]')
if [ "$(echo "$pods" | jq length)" -ne 3 ]; then
  echo "❌ ledger-api: rollout still in progress"
  exit 1
fi
echo "✅ ledger-api: 3 of 3 replicas Ready"

a=$(worker_n 1); b=$(worker_n 2)
ca=$(echo "$pods" | jq --arg n "$a" '[.[] | select(.spec.nodeName==$n)] | length')
cb=$(echo "$pods" | jq --arg n "$b" '[.[] | select(.spec.nodeName==$n)] | length')
if [ $((ca + cb)) -ne 3 ]; then
  echo "❌ only $((ca + cb)) of 3 replicas run on the worker nodes; the control plane is not an option"
  exit 1
fi
if [ "$ca" -eq 0 ] || [ "$cb" -eq 0 ]; then
  echo "❌ all 3 replicas share one worker ($ca / $cb): losing that node loses the service"
  exit 1
fi
echo "✅ replicas are split $ca / $cb over the workers"
exit 0
exit 1
