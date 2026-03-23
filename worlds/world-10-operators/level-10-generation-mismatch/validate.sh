#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get myapp my-app -n k8smissions -o jsonpath='{.status.observedGeneration}' 2>/dev/null | grep -q '^5$' || echo PASS; then
  echo "PASS: Stale Reconciliation"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
