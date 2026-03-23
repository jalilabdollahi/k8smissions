#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl auth can-i create pipelineruns.tekton.dev -n k8smissions --as=system:serviceaccount:k8smissions:trigger-sa 2>/dev/null | grep -q yes; then
  echo "PASS: Pipeline Locked Out"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
