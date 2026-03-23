#!/bin/bash
set -euo pipefail
NS="k8smissions"

IMAGE=$(kubectl get deployment helm-app -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)
if [ "$IMAGE" = "nginx:1.27.4" ]; then
  echo "✅ PASS: Helm proxy deployment is pinned to a version"
  exit 0
fi
echo "❌ FAIL: Deployment image is '$IMAGE'"
exit 1
