#!/bin/bash
set -euo pipefail
NS="k8smissions"
MIN_AVAIL=$(kubectl get pdb my-pdb -n k8smissions -o jsonpath='{.spec.minAvailable}' 2>/dev/null || true)
if [ -n "$MIN_AVAIL" ] && [ "$MIN_AVAIL" != "3" ]; then
  echo "PASS: Deployment Stuck"
  exit 0
fi
echo "FAIL: check broken configuration"
exit 1
