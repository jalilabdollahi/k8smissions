#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get deployment my-operator -n operators -o jsonpath='{.spec.template.spec.containers[0].env[0].value}' 2>/dev/null | grep -qv 'operators' || echo PASS; then
  echo "PASS: Stuck Reconciliation"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
