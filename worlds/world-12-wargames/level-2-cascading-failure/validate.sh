#!/bin/bash
set -euo pipefail
NS="k8smissions"

READY=$(kubectl get deployment auth-svc -n "$NS" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)
if [ "$READY" = "2" ]; then
  echo "✅ PASS: auth-svc is running with 2 ready replicas"
  exit 0
fi
echo "❌ FAIL: auth-svc readyReplicas='$READY'"
exit 1
