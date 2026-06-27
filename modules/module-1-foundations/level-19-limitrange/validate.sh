#!/bin/bash
set -euo pipefail
NS="k8smissions"
STATUS=$(kubectl get pod noisy-pod -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null || true)
READY=$(kubectl get pod noisy-pod -n "$NS" -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null || true)
LIMIT=$(kubectl get pod noisy-pod -n "$NS" -o jsonpath='{.spec.containers[0].resources.limits.memory}' 2>/dev/null || true)
if [ "$STATUS" = "Running" ] && [ "$READY" = "true" ] && [ "$LIMIT" = "128Mi" ]; then
  echo "PASS: Pod is running with an explicit 128Mi memory limit"
  exit 0
fi
echo "FAIL: Pod status=$STATUS ready=$READY memory-limit=$LIMIT (expected 128Mi)"
exit 1
