#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get serviceaccount ci-sa -n k8smissions -o jsonpath='{.secrets}' 2>/dev/null | grep -q registry; then
  echo "PASS: Push Denied"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
