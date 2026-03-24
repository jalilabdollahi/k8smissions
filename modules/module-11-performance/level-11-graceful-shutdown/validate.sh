#!/bin/bash
set -euo pipefail
NS="k8smissions"
GRACE=$(kubectl get deployment web-server -n k8smissions -o jsonpath='{.spec.template.spec.terminationGracePeriodSeconds}' 2>/dev/null || true)
if [ -n "$GRACE" ] && [ "$GRACE" != "5" ]; then
  echo "PASS: In-Flight Request Drop"
  exit 0
fi
echo "FAIL: check broken configuration"
exit 1
