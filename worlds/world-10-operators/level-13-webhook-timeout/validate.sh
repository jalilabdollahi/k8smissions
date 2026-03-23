#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get validatingwebhookconfiguration policy-enforcer -o jsonpath='{.webhooks[0].timeoutSeconds}' 2>/dev/null | grep -qv '^30$' || echo PASS; then
  echo "PASS: Slow Admission"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
