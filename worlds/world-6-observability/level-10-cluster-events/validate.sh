#!/bin/bash
set -euo pipefail
NS="k8smissions"

LIMIT=$(kubectl get deployment incident-app -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null || true)
if [ "$LIMIT" = "256Mi" ]; then
  echo "✅ PASS: Incident root cause has been mitigated"
  exit 0
fi
echo "❌ FAIL: Memory limit is still '$LIMIT'"
exit 1
