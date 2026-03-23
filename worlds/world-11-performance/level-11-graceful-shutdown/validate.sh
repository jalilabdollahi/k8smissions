#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get deployment web-server -n k8smissions -o jsonpath='{.spec.template.spec.terminationGracePeriodSeconds}' 2>/dev/null | grep -qv '^5$' || echo PASS; then
  echo "PASS: In-Flight Request Drop"
  exit 0
fi
echo "FAIL: check broken configuration"
exit 1
