#!/bin/bash
set -euo pipefail
NS="k8smissions"

VALUE=$(kubectl get deployment cpu-hog -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}' 2>/dev/null || true)
if [ "$VALUE" = "200m" ]; then
  echo "✅ PASS: CPU limit set to 200m"
  exit 0
fi
echo "❌ FAIL: CPU limit has not been fixed. Current value: '$VALUE'"
exit 1
