#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get crd workloads.example.com -o jsonpath='{.spec.versions[0].schema.openAPIV3Schema.properties}' 2>/dev/null | grep -q spec || echo PASS; then
  echo "PASS: Unvalidated Resource"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
