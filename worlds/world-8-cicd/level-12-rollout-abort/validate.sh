#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get rollout web-rollout -n k8smissions -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null | grep -qv bad-tag; then
  echo "PASS: Reverted Release"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
