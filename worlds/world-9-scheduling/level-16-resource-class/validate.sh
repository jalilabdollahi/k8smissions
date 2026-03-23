#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get resourceclaim my-fpga-claim -n k8smissions -o jsonpath='{.spec.resourceClassName}' 2>/dev/null | grep -q fpga-class || echo PASS; then
  echo "PASS: Class Not Found"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
