#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get serviceaccount pipeline-sa -n k8smissions -o jsonpath='{.secrets}' 2>/dev/null | grep -q git-ssh; then
  echo "PASS: Clone Denied"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
