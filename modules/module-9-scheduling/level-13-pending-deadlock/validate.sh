#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get validatingwebhookconfiguration strict-validator -o jsonpath='{.webhooks[0].failurePolicy}' 2>/dev/null | grep -q Ignore; then
  echo "PASS: Scheduler Deadlock"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
