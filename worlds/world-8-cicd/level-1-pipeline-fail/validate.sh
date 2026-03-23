#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get task build-task -n k8smissions -o jsonpath='{.spec.steps[0].image}' 2>/dev/null | grep -v '99.9'; then
  echo "PASS: Broken Stage"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
