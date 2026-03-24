#!/bin/bash
set -euo pipefail
NS="k8smissions"

READY=$(kubectl get deployment api-watcher -n "$NS" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)
if [ "$READY" = "2" ]; then
  echo "✅ PASS: api-watcher scaled down to 2 replicas"
  exit 0
fi
echo "❌ FAIL: api-watcher has $READY ready replicas"
exit 1
