#!/bin/bash
set -euo pipefail
NS="k8smissions"

REPLICAS=$(kubectl get deployment metrics-server -n "$NS" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)
if [ "$REPLICAS" = "1" ]; then
  echo "✅ PASS: metrics-server proxy deployment is ready"
  exit 0
fi
echo "❌ FAIL: metrics-server proxy is not ready"
exit 1
