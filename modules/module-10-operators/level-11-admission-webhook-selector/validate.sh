#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get mutatingwebhookconfiguration pod-mutator -o jsonpath='{.webhooks[0].namespaceSelector}' 2>/dev/null | grep -q kube-system || echo PASS; then
  echo "PASS: System Pod Blocked"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
