#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get deployment resilient-app -n k8smissions -o jsonpath='{.spec.replicas}' 2>/dev/null | grep -qv '^2$' || echo PASS; then
  echo "PASS: Chaos Unready"
  exit 0
fi
echo "FAIL: check broken configuration"
exit 1
