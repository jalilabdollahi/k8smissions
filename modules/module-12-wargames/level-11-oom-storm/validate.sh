#!/bin/bash
set -euo pipefail
NS="k8smissions"

PASS=0
for SVC in svc-alpha svc-beta svc-gamma; do
  LIMIT=$(kubectl get deployment "$SVC" -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null || true)
  if [ "$LIMIT" = "256Mi" ]; then
    PASS=$((PASS+1))
  fi
done
if [ "$PASS" = "3" ]; then
  echo "✅ PASS: All 3 deployments have safe memory limits (256Mi)"
  exit 0
fi
echo "❌ FAIL: Only $PASS/3 deployments have correct limits"
exit 1
