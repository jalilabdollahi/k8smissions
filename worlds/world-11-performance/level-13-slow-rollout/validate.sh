#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get deployment slow-deploy -n k8smissions -o jsonpath='{.spec.strategy.rollingUpdate.maxSurge}' 2>/dev/null | grep -qv '^0$' || echo PASS; then
  echo "PASS: Deployment Takes Hours"
  exit 0
fi
echo "FAIL: check broken configuration"
exit 1
