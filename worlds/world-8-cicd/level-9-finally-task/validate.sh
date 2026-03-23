#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get pipeline build-and-clean -n k8smissions -o jsonpath='{.spec.finally}' 2>/dev/null | grep -q cleanup; then
  echo "PASS: Cleanup Skipped"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
