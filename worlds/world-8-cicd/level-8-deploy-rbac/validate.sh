#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl auth can-i create deployments -n k8smissions --as=system:serviceaccount:k8smissions:deploy-sa 2>/dev/null | grep -q yes; then
  echo "PASS: Blocked Deploy"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
