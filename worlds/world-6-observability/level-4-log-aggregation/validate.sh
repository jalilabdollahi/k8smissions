#!/bin/bash
set -euo pipefail
NS="k8smissions"

STATUS=$(kubectl get pod logs-pod -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null || true)
READY=$(kubectl get pod logs-pod -n "$NS" -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null || true)
if [ "$STATUS" = "Running" ] && [ "$READY" = "true" ]; then
  echo "✅ PASS: Pod is stable"
  exit 0
fi
echo "❌ FAIL: Pod still is not stable. Status='$STATUS' Ready='$READY'"
exit 1
