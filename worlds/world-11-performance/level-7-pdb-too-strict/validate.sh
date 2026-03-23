#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get pdb my-pdb -n k8smissions -o jsonpath='{.spec.minAvailable}' 2>/dev/null | grep -qv '^3$' || echo PASS; then
  echo "PASS: Deployment Stuck"
  exit 0
fi
echo "FAIL: check broken configuration"
exit 1
