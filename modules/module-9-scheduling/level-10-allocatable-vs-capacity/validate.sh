#!/bin/bash
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
k() { kubectl -n "$NS" "$@"; }

# the other tenants must still be there
if [ "$(k get pods -l app=tenant-hold --field-selector=status.phase=Running -o name 2>/dev/null | wc -l)" -ne 2 ]; then
  echo "❌ the tenant-* Deployments must keep both of their pods running"
  exit 1
fi
echo "✅ tenant-* Deployments are untouched"

rc=$(kubectl get runtimeclass sandboxed -o jsonpath='{.overhead.podFixed.memory}' 2>/dev/null)
if [ -z "$rc" ] || [ "$(mem_to_mi "$rc")" -lt 700 ]; then
  echo "❌ RuntimeClass sandboxed must keep its 700Mi pod overhead (found: ${rc:-no class})"
  exit 1
fi

pods=$(k get pods -l app=ledger-batch -o json | jq '[.items[] | select(.metadata.deletionTimestamp==null)]')
n=$(echo "$pods" | jq length)
if [ "$n" -ne 1 ]; then
  echo "❌ ledger-batch: expected exactly 1 pod, found $n"
  exit 1
fi
node=$(echo "$pods" | jq -r '.[0].spec.nodeName // ""')
ready=$(echo "$pods" | jq -r '.[0] | select(any(.status.conditions[]?; .type=="Ready" and .status=="True")) | .metadata.name')
if [ -z "$node" ] || [ -z "$ready" ]; then
  echo "❌ ledger-batch: pod is not Running and Ready yet (node: ${node:-none})"
  exit 1
fi
if ! workers | grep -qx "$node"; then
  echo "❌ ledger-batch runs on $node, which is not a worker"
  exit 1
fi
echo "✅ ledger-batch is Running on worker $node"

if [ "$(echo "$pods" | jq -r '.[0].spec.runtimeClassName')" != "sandboxed" ]; then
  echo "❌ ledger-batch no longer runs under RuntimeClass sandboxed"
  exit 1
fi
ov=$(echo "$pods" | jq -r '.[0].spec.overhead.memory // "0"')
if [ "$(mem_to_mi "$ov")" -lt 700 ]; then
  echo "❌ ledger-batch pod carries no sandbox overhead (found ${ov})"
  exit 1
fi
echo "✅ the pod runs sandboxed with its ${ov} overhead applied"

req=$(echo "$pods" | jq -r '.[0].spec.containers[0].resources.requests.memory // "0"')
need=$(k get configmap ledger-batch-sizing -o jsonpath='{.data.measured-working-set-mi}' 2>/dev/null)
if [ "$(mem_to_mi "$req")" -lt "${need:-300}" ]; then
  echo "❌ ledger-batch requests ${req}, less than its measured working set of ${need:-300}Mi"
  exit 1
fi
echo "✅ ledger-batch requests ${req}, enough for the measured working set"

sleep 8
r=$(k get pod -l app=ledger-batch -o jsonpath='{.items[0].status.containerStatuses[0].restartCount}')
if [ "${r:-1}" -ne 0 ]; then
  echo "❌ ledger-batch restarted ${r} time(s)"
  exit 1
fi
echo "✅ ledger-batch is stable"
exit 0
exit 1
