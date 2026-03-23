#!/bin/bash
set -euo pipefail
NS="k8smissions"
STATUS=$(kubectl get pod noisy-pod -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null || true)
if [ "$STATUS" = "Running" ]; then
  echo "PASS: Pod is running within LimitRange constraints"
  exit 0
fi
echo "FAIL: Pod status=$STATUS"
exit 1
