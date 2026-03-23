#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get pod critical-app -n k8smissions -o jsonpath='{.spec.tolerations}' 2>/dev/null | grep -q NoExecute; then
  echo "PASS: Sudden Eviction"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
