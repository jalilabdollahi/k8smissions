#!/bin/bash
set -euo pipefail
NS="k8smissions"

METRICS=$(kubectl get deployment metrics-server -n "$NS" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)
if [ "$METRICS" = "1" ]; then
  echo "✅ PASS: Metrics server proxy is running"
  exit 0
fi
echo "❌ FAIL: metrics-server proxy is not ready"
exit 1
