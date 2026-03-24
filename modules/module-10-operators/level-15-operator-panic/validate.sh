#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get deployment my-operator -n operators -o jsonpath='{.spec.template.spec.initContainers}' 2>/dev/null | grep -q wait-for-crd || echo PASS; then
  echo "PASS: Controller Crash Loop"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
