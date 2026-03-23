#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get task injected-task -n k8smissions -o jsonpath='{.spec.podTemplate}' 2>/dev/null | grep -qv '^$'; then
  echo "PASS: Injected to Failure"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
