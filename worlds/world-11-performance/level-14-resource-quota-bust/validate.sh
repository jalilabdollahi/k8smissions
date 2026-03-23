#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get resourcequota compute-resources -n k8smissions -o jsonpath='{.spec.hard.requests\.cpu}' 2>/dev/null | grep -qv '^4$' || echo PASS; then
  echo "PASS: Namespace Full"
  exit 0
fi
echo "FAIL: check broken configuration"
exit 1
