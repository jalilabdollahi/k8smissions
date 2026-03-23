#!/bin/bash
set -euo pipefail
NS="k8smissions"

MODE=$(kubectl get configmap app-config -n "$NS" -o jsonpath='{.data.APP_MODE}' 2>/dev/null || true)
READY=$(kubectl get deployment config-app -n "$NS" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)
if [ -n "$MODE" ] && [ "$READY" = "3" ]; then
  echo "✅ PASS: ConfigMap is populated and all pods are Running"
  exit 0
fi
echo "❌ FAIL: APP_MODE='$MODE' readyReplicas='$READY'"
exit 1
