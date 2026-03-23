#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get task multi-task -n k8smissions -o jsonpath='{.spec.steps[0].image}' 2>/dev/null | grep -qv '999'; then
  echo "PASS: Full Pipeline Down"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
