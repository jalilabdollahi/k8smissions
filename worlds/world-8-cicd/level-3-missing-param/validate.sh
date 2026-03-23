#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get taskrun push-run -n k8smissions -o jsonpath='{.spec.params}' 2>/dev/null | grep -q IMAGE; then
  echo "PASS: Missing Parameter"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
