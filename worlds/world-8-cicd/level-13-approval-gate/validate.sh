#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get taskrun approval-gate -n k8smissions -o jsonpath='{.metadata.annotations.awaiting-approval}' 2>/dev/null | grep -qv 'true'; then
  echo "PASS: Manual Block"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
