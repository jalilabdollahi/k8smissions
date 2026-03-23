#!/bin/bash
set -euo pipefail
NS="k8smissions"

READY=$(kubectl get deployment ghost-deployment -n "$NS" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)
if [ "$READY" = "3" ]; then
  echo "✅ PASS: Deployment has 3 ready replicas"
  exit 0
fi
echo "❌ FAIL: Expected 3 ready replicas, got '$READY'"
exit 1
