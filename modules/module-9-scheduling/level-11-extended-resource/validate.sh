#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get pod fpga-pod -n k8smissions -o jsonpath='{.spec.containers[0].resources}' 2>/dev/null | grep -q 'company.io'; then
  echo "PASS: Custom Resource Request"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
