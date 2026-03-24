#!/bin/bash
set -euo pipefail
NS="k8smissions"
RS=$(kubectl get replicaset legacy-app-7d8f9 -n "$NS" 2>&1 || true)
if echo "$RS" | grep -q "not found"; then
  echo "PASS: Orphaned ReplicaSet has been deleted"
  exit 0
fi
echo "FAIL: ReplicaSet still exists"
exit 1
