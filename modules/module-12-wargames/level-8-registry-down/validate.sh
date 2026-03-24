#!/bin/bash
set -euo pipefail
NS="k8smissions"

IMAGE=$(kubectl get deployment registry-app -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)
READY=$(kubectl get deployment registry-app -n "$NS" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)
if [ "$READY" = "2" ]; then
  echo "✅ PASS: Deployment is running with a reachable image"
  exit 0
fi
echo "❌ FAIL: readyReplicas='$READY' image='$IMAGE'"
exit 1
