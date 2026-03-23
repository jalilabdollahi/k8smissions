#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get triggerbinding git-push-binding -n k8smissions -o jsonpath='{.spec.params[0].value}' 2>/dev/null | grep -q head_commit; then
  echo "PASS: Webhook Ignored"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
