#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get taskrun build-cache-run -n k8smissions -o jsonpath='{.spec.workspaces}' 2>/dev/null | grep -q cache; then
  echo "PASS: No Cache Hit"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
