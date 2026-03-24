#!/bin/bash
set -euo pipefail
NS="k8smissions"

if ! kubectl get configmap app-config -n "$NS" >/dev/null 2>&1; then
  echo "❌ FAIL: ConfigMap app-config does not exist"
  exit 1
fi
STATUS=$(kubectl get pod configmap-pod -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null || true)
if [ "$STATUS" = "Running" ]; then
  echo "✅ PASS: ConfigMap exists and pod is running"
  exit 0
fi
echo "❌ FAIL: Pod status is '$STATUS'"
exit 1
