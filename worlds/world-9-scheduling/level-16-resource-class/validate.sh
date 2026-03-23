#!/bin/bash
set -euo pipefail
NS="k8smissions"
# Check if the ResourceClass 'fpga-class' exists (the solution creates it)
# OR the ResourceClaim now references the correct class name
if kubectl get resourceclass fpga-class 2>/dev/null | grep -q fpga-class; then
  echo "PASS: Class Not Found"
  exit 0
fi
if kubectl get resourceclaim my-fpga-claim -n "$NS" -o jsonpath='{.spec.resourceClassName}' 2>/dev/null | grep -q 'fpga-class'; then
  echo "PASS: Class Not Found"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
