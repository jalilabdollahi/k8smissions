#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get deployment my-app-deploy -n k8smissions -o jsonpath='{.metadata.ownerReferences}' 2>/dev/null | grep -q MyApp || echo PASS; then
  echo "PASS: Orphaned Resources"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
