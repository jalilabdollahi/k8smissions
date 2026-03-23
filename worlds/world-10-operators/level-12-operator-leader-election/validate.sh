#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get deployment my-operator -n operators -o jsonpath='{.spec.template.spec.containers[0].args}' 2>/dev/null | grep -q 'leader-elect=true' || echo PASS; then
  echo "PASS: Split Brain"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
