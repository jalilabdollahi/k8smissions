#!/bin/bash
set -euo pipefail
NS="k8smissions"

STATUS=$(kubectl get pod crashloop-pod -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null || true)
RESTARTS=$(kubectl get pod crashloop-pod -n "$NS" -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>/dev/null || true)
if [ "$STATUS" = "Running" ] && [ "$RESTARTS" = "0" ]; then
  echo "✅ PASS: Pod is stable and no longer restarting"
  exit 0
fi
echo "❌ FAIL: Pod status='$STATUS' restarts='$RESTARTS'"
exit 1
