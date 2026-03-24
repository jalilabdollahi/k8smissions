#!/bin/bash
set -euo pipefail
NS="k8smissions"

if ! kubectl get secret db-credentials -n "$NS" >/dev/null 2>&1; then
  echo "❌ FAIL: Secret db-credentials does not exist"
  exit 1
fi
READY=$(kubectl get deployment secret-app -n "$NS" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)
if [ "$READY" = "2" ]; then
  echo "✅ PASS: Secret restored and pods are running"
  exit 0
fi
echo "❌ FAIL: readyReplicas='$READY'"
exit 1
