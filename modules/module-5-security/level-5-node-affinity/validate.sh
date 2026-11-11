#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

# the label must stay on exactly one node, and every node stays schedulable
nodes=$(kubectl get nodes -l data-class=restricted -o jsonpath='{.items[*].metadata.name}')
if [ "$(echo $nodes | wc -w)" -ne 1 ]; then
  echo "❌ exactly one node must carry data-class=restricted (found: ${nodes:-none})"
  exit 1
fi
if kubectl get nodes -o jsonpath='{.items[*].spec.unschedulable}' | grep -q true; then
  echo "❌ a node is cordoned; placement must come from the workload, not from node state"
  exit 1
fi
echo "✅ one node carries data-class=restricted ($nodes)"

if [ "$(k get deploy ledger-api -o jsonpath='{.spec.replicas}' 2>/dev/null)" != "4" ]; then
  echo "❌ Deployment ledger-api must exist with 4 replicas"
  exit 1
fi

# the placement must be a rule in the pod template, not luck
rule=$(k get deploy ledger-api -o jsonpath='{.spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution}{.spec.template.spec.nodeSelector}' 2>/dev/null)
if ! echo "$rule" | grep -q 'data-class'; then
  echo "❌ the pod template has no hard placement rule for data-class"
  exit 1
fi
echo "✅ the pod template carries a hard rule for data-class"

if ! k rollout status deploy/ledger-api --timeout=60s >/dev/null 2>&1; then
  echo "❌ ledger-api is not fully rolled out"
  exit 1
fi
placed=$(k get pods -l app=ledger-api --field-selector=status.phase=Running -o jsonpath='{range .items[*]}{.metadata.deletionTimestamp}{"|"}{.spec.nodeName}{"\n"}{end}')
total=$(echo "$placed" | grep -c '|')
good=$(echo "$placed" | grep -c "^|$nodes\$")
if [ "$total" -lt 4 ] || [ "$good" -ne "$total" ]; then
  echo "❌ $good of $total ledger-api pods are on the restricted node"
  exit 1
fi
echo "✅ all $total ledger-api pods run on the restricted node"
exit 0
exit 1
