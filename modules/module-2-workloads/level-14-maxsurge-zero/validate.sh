#!/bin/bash
set -euo pipefail
NS="k8smissions"
MAX_SURGE=$(kubectl get deployment api-server -n "$NS" -o jsonpath='{.spec.strategy.rollingUpdate.maxSurge}' 2>/dev/null || echo "0")
MAX_UNAVAIL=$(kubectl get deployment api-server -n "$NS" -o jsonpath='{.spec.strategy.rollingUpdate.maxUnavailable}' 2>/dev/null || echo "0")
if [ "$MAX_SURGE" != "0" ] || [ "$MAX_UNAVAIL" != "0" ]; then
  echo "PASS: maxSurge=$MAX_SURGE maxUnavailable=$MAX_UNAVAIL — rollout can proceed"
  exit 0
fi
echo "FAIL: Both maxSurge=$MAX_SURGE and maxUnavailable=$MAX_UNAVAIL are 0 — rollout blocked"
exit 1
