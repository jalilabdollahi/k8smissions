#!/bin/bash
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
k() { kubectl -n "$NS" "$@"; }

node=$(kubectl get nodes -l disktype=nvme -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$node" ]; then
  echo "❌ no node carries disktype=nvme any more"
  exit 1
fi
if ! kubectl get node "$node" -o json | jq -e '.spec.taints // [] | any(.key=="maintenance" and .effect=="NoExecute")' >/dev/null; then
  echo "❌ the maintenance taint is gone from $node: the window is still open and must stay enforced"
  exit 1
fi
echo "✅ $node is still in its maintenance window (taint present)"

replicas=$(k get deploy session-cache -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ "${replicas:-0}" -ne 2 ]; then
  echo "❌ Deployment session-cache has ${replicas:-0} replicas, expected 2"
  exit 1
fi

pods=$(k get pods -l app=session-cache -o json 2>/dev/null | jq '[.items[] | select(.metadata.deletionTimestamp==null)]')
n=$(echo "$pods" | jq 'length')
if [ "$n" -ne 2 ]; then
  echo "❌ session-cache has $n live pods, expected 2"
  exit 1
fi
short=$(echo "$pods" | jq '[.[] | select((.spec.tolerations // []) | any(
  (.key=="maintenance" or (.key==null and .operator=="Exists")) and (.effect==null or .effect=="NoExecute")
  and (.tolerationSeconds==null or .tolerationSeconds>=1800)) | not)] | length')
if [ "$short" -ne 0 ]; then
  echo "❌ $short session-cache pod(s) would still be evicted before the 30-minute window ends"
  exit 1
fi
echo "✅ the pods' tolerance outlasts the maintenance window"

off=$(echo "$pods" | jq --arg n "$node" '[.[] | select(.spec.nodeName != $n or .status.phase != "Running")] | length')
if [ "$off" -ne 0 ]; then
  echo "❌ $off session-cache pod(s) are not Running on $node"
  exit 1
fi
before=$(echo "$pods" | jq -r '[.[].metadata.uid] | sort | join(",")')
sleep 25
after=$(k get pods -l app=session-cache -o json | jq -r '[.items[] | select(.metadata.deletionTimestamp==null) | .metadata.uid] | sort | join(",")')
restarts=$(k get pods -l app=session-cache -o json | jq '[.items[].status.containerStatuses[]?.restartCount] | add // 0')
if [ "$before" != "$after" ] || [ "$restarts" -ne 0 ]; then
  echo "❌ session-cache pods were replaced or restarted during the 25s observation window"
  exit 1
fi
echo "✅ both session-cache pods stayed up on $node for 25s past the old limit"
exit 0
exit 1
