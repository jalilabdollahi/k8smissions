#!/bin/bash
set -euo pipefail
NS="k8smissions"

STARTUP=$(kubectl get deployment slow-app -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].startupProbe.periodSeconds}' 2>/dev/null || true)
if [ "$STARTUP" = "5" ]; then
  echo "✅ PASS: startupProbe configured"
  exit 0
fi
echo "❌ FAIL: startupProbe is missing"
exit 1
