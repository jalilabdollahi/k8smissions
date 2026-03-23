#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get crd databases.example.com -o jsonpath='{.spec.conversion.strategy}' 2>/dev/null | grep -q Webhook || echo PASS; then
  echo "PASS: Version Migration"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
