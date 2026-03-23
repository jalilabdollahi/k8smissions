#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get pipeline ci-pipeline -n k8smissions -o jsonpath='{.spec.tasks}' 2>/dev/null | grep -q build; then
  echo "PASS: Build Corruption"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
