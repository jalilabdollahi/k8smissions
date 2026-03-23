#!/bin/bash
set -euo pipefail
NS="k8smissions"

LEVEL=$(kubectl get configmap env-config -n "$NS" -o jsonpath='{.data.LOG_LEVEL}' 2>/dev/null || true)
REPLICAS=$(kubectl get deployment multi-env-app -n "$NS" -o jsonpath='{.spec.replicas}' 2>/dev/null || true)
CPU=$(kubectl get deployment multi-env-app -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}' 2>/dev/null || true)
if [ "$LEVEL" = "info" ] && [ "$REPLICAS" = "3" ] && [ "$CPU" = "500m" ]; then
  echo "✅ PASS: Production overlay proxy looks correct"
  exit 0
fi
echo "❌ FAIL: log_level='$LEVEL' replicas='$REPLICAS' cpu='$CPU'"
exit 1
