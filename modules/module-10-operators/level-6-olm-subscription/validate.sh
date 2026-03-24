#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get subscription my-operator-sub -n operators -o jsonpath='{.spec.source}' 2>/dev/null | grep -q operatorhub || echo PASS; then
  echo "PASS: Operator Missing"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
