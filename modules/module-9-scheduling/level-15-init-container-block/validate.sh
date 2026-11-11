#!/bin/bash
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
k() { kubectl -n "$NS" "$@"; }

pods=$(k get pods -l app=payments-migrator -o json | jq '[.items[] | select(.metadata.deletionTimestamp==null)]')
if [ "$(echo "$pods" | jq length)" -ne 1 ]; then
  echo "❌ payments-migrator: expected exactly 1 pod, found $(echo "$pods" | jq length)"
  exit 1
fi
node=$(echo "$pods" | jq -r '.[0].spec.nodeName // ""')
if [ -z "$node" ]; then
  echo "❌ payments-migrator pod is not scheduled yet"
  exit 1
fi
if ! workers | grep -qx "$node"; then
  echo "❌ payments-migrator runs on $node, which is not a worker"
  exit 1
fi
echo "✅ the pod is scheduled on worker $node"

if [ "$(echo "$pods" | jq -r '.[0].status.initContainerStatuses[0].state.terminated.exitCode // "x"')" != "0" ]; then
  reason=$(echo "$pods" | jq -r '.[0].status.initContainerStatuses[0] | (.lastState.terminated.reason // .state.terminated.reason // .state.waiting.reason // "not finished")')
  echo "❌ the db-migrate init container has not completed (${reason})"
  exit 1
fi
if ! k logs "$(echo "$pods" | jq -r '.[0].metadata.name')" -c db-migrate 2>/dev/null | grep -q "migrated 214 tables"; then
  echo "❌ db-migrate did not log 'migrated 214 tables'"
  exit 1
fi
echo "✅ the migration completed"

lim=$(echo "$pods" | jq -r '.[0].spec.initContainers[0].resources.limits.memory // ""')
if [ -n "$lim" ] && [ "$(mem_to_mi "$lim")" -lt 600 ]; then
  echo "❌ db-migrate is limited to ${lim}, less than the migration needs"
  exit 1
fi

if [ "$(echo "$pods" | jq '[.[0].status.conditions[] | select(.type=="Ready" and .status=="True")] | length')" -ne 1 ]; then
  echo "❌ the pod is not Ready yet"
  exit 1
fi
echo "✅ payments-migrator is Running and Ready"
exit 0
exit 1
