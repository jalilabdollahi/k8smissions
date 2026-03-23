#!/bin/bash
set -euo pipefail
NS="k8smissions"

STATUS=$(kubectl get pod selector-pod -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null || true)
if [ "$STATUS" = "Running" ]; then
  echo "✅ PASS: Pod scheduled successfully"
  exit 0
fi
echo "❌ FAIL: Pod status is '$STATUS'"
exit 1
