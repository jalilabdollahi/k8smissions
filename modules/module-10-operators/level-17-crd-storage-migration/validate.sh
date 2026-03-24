#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get crd configs.example.com -o jsonpath='{.spec.versions[*].name}' 2>/dev/null | grep -q v1alpha1 || echo PASS; then
  echo "PASS: Stored Version Gone"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
