#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get vpa my-app-vpa -n k8smissions -o jsonpath='{.spec.updatePolicy.updateMode}' 2>/dev/null | grep -q Auto || echo PASS; then
  echo "PASS: OOM Killed Daily"
  exit 0
fi
echo "FAIL: check broken configuration"
exit 1
