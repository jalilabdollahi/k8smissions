#!/bin/bash
set -euo pipefail
NS="k8smissions"

if ! kubectl get secret db-credentials -n "$NS" >/dev/null 2>&1; then
  echo "❌ FAIL: Secret db-credentials does not exist"
  exit 1
fi
STATUS=$(kubectl get pod secret-pod -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null || true)
if [ "$STATUS" = "Running" ]; then
  echo "✅ PASS: Secret exists and pod is running"
  exit 0
fi
echo "❌ FAIL: Pod status is '$STATUS'"
exit 1
