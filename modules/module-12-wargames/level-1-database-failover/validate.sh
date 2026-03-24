#!/bin/bash
set -euo pipefail
NS="k8smissions"

STATUS=$(kubectl get pod db-primary -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null || true)
if [ "$STATUS" = "Running" ]; then
  echo "✅ PASS: DB primary pod is restored and running"
  exit 0
fi
echo "❌ FAIL: db-primary pod status='$STATUS'"
exit 1
