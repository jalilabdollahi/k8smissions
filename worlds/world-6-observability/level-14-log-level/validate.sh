#!/bin/bash
set -euo pipefail
NS="k8smissions"
LEVEL=$(kubectl get pod logger-app -n "$NS" -o jsonpath='{.spec.containers[0].env[0].value}' 2>/dev/null || true)
if [ "$LEVEL" = "INFO" ] || [ "$LEVEL" = "WARN" ] || [ "$LEVEL" = "ERROR" ]; then
  echo "PASS: LOG_LEVEL=$LEVEL"
  exit 0
fi
echo "FAIL: LOG_LEVEL=$LEVEL (use INFO, WARN, or ERROR)"
exit 1
