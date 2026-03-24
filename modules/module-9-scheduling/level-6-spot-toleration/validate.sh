#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get deployment batch-job -n k8smissions -o jsonpath='{.spec.template.spec.tolerations}' 2>/dev/null | grep -q on-demand; then
  echo "PASS: Spot Survivor"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
