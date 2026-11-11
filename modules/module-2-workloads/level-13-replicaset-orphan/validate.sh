#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get deploy checkout >/dev/null 2>&1; then
  echo "❌ Deployment checkout does not exist"
  exit 1
fi
if ! k get svc checkout >/dev/null 2>&1; then
  echo "❌ Service checkout does not exist"
  exit 1
fi

orphans=$(k get rs -o jsonpath='{range .items[*]}{.metadata.name}{"|"}{.metadata.ownerReferences[*].kind}{"\n"}{end}' | grep -c '|$')
if [ "$orphans" -ne 0 ]; then
  echo "❌ $orphans ReplicaSet(s) have no owning Deployment"
  exit 1
fi
echo "✅ every ReplicaSet belongs to a Deployment"

if ! k rollout status deploy/checkout --timeout=40s >/dev/null 2>&1; then
  echo "❌ Deployment checkout is not fully available"
  exit 1
fi
avail=$(k get deploy checkout -o jsonpath='{.status.availableReplicas}')
if [ "${avail:-0}" -ne 3 ]; then
  echo "❌ checkout: ${avail:-0} of 3 replicas available"
  exit 1
fi
echo "✅ checkout has 3 of 3 replicas available"

# Pods that are not owned by the Deployment's ReplicaSet and still match the Service.
out=$(k exec probe -- sh -c 'for i in $(seq 20); do curl -s --max-time 2 http://checkout; echo; done' 2>/dev/null)
v2=$(echo "$out" | grep -c '^v2$')
if [ "$v2" -ne 20 ]; then
  echo "❌ checkout: only $v2 of 20 answers were v2"
  exit 1
fi
echo "✅ checkout: 20 of 20 answers are v2"
exit 0
exit 1
