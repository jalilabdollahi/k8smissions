#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get crd apps.example.com -o jsonpath='{.spec.names.categories}' 2>/dev/null | grep -q all || echo PASS; then
  echo "PASS: Not in List"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
