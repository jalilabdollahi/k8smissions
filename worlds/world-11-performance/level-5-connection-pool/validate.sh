#!/bin/bash
set -euo pipefail
NS="k8smissions"
POOL_SIZE=$(kubectl get deployment web-app -n k8smissions -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="DB_POOL_SIZE")].value}' 2>/dev/null || true)
if [ -n "$POOL_SIZE" ] && [ "$POOL_SIZE" != "1" ]; then
  echo "PASS: Database Stampede"
  exit 0
fi
echo "FAIL: check broken configuration"
exit 1
