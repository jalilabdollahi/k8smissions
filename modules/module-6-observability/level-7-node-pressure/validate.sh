#!/bin/bash
set -euo pipefail
NS="k8smissions"

REPLICAS=$(kubectl get deployment memory-hog -n "$NS" -o jsonpath='{.spec.replicas}' 2>/dev/null || true)
LIMIT=$(kubectl get deployment memory-hog -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null || true)
if [ "$REPLICAS" = "1" ] && [ "$LIMIT" = "128Mi" ]; then
  echo "✅ PASS: Memory pressure proxy has been reduced"
  exit 0
fi
echo "❌ FAIL: replicas='$REPLICAS' limit='$LIMIT'"
exit 1
