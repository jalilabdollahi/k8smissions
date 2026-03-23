#!/bin/bash
set -euo pipefail
NS="k8smissions"
MAX_SURGE=$(kubectl get deployment slow-deploy -n k8smissions -o jsonpath='{.spec.strategy.rollingUpdate.maxSurge}' 2>/dev/null || true)
if [ -n "$MAX_SURGE" ] && [ "$MAX_SURGE" != "0" ]; then
  echo "PASS: Deployment Takes Hours"
  exit 0
fi
echo "FAIL: check broken configuration"
exit 1
