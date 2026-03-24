#!/bin/bash
set -euo pipefail
NS="k8smissions"

LIMIT=$(kubectl get pod oom-pod -n "$NS" -o jsonpath='{.spec.containers[0].resources.limits.memory}' 2>/dev/null || true)
if [ "$LIMIT" = "256Mi" ]; then
  echo "✅ PASS: Memory limit increased to 256Mi"
  exit 0
fi
echo "❌ FAIL: Expected memory limit 256Mi, got '$LIMIT'"
exit 1
