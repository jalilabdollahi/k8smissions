#!/bin/bash
set -euo pipefail
NS="k8smissions"
THRESHOLD=$(kubectl get pod fragile-app -n "$NS" -o jsonpath='{.spec.containers[0].livenessProbe.failureThreshold}' 2>/dev/null || true)
if [ -n "$THRESHOLD" ] && [ "$THRESHOLD" -ge 3 ]; then
  echo "PASS: failureThreshold=$THRESHOLD — tolerates transient failures"
  exit 0
fi
echo "FAIL: failureThreshold=$THRESHOLD (must be >= 3)"
exit 1
