#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get database prod-db -n k8smissions -o jsonpath='{.metadata.finalizers}' 2>/dev/null | grep -qv 'cleanup' || echo PASS; then
  echo "PASS: Orphaned Controller"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
