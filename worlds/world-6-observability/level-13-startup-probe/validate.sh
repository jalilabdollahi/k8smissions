#!/bin/bash
set -euo pipefail
NS="k8smissions"
STARTUP=$(kubectl get pod slow-java-app -n "$NS" -o jsonpath='{.spec.containers[0].startupProbe}' 2>/dev/null || true)
if [ -n "$STARTUP" ] && [ "$STARTUP" != "null" ]; then
  echo "PASS: startupProbe is configured"
  exit 0
fi
echo "FAIL: No startupProbe found"
exit 1
