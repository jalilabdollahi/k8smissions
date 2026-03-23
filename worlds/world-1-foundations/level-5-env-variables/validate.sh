#!/bin/bash
set -euo pipefail
NS="k8smissions"

STATUS=$(kubectl get pod env-pod -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null || true)
READY=$(kubectl get pod env-pod -n "$NS" -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null || true)
if [ "$STATUS" = "Running" ] && [ "$READY" = "true" ]; then
  echo "✅ PASS: Pod is running with DATABASE_URL set"
  exit 0
fi
echo "❌ FAIL: Pod is still crashing. Status='$STATUS' Ready='$READY'"
exit 1
