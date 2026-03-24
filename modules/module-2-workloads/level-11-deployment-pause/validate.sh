#!/bin/bash
set -euo pipefail
NS="k8smissions"
PAUSED=$(kubectl get deployment frontend -n "$NS" -o jsonpath='{.spec.paused}' 2>/dev/null || true)
READY=$(kubectl get deployment frontend -n "$NS" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo 0)
if [ "$PAUSED" != "true" ] && [ "${READY:-0}" -ge 1 ]; then
  echo "PASS: Deployment is running and unpaused"
  exit 0
fi
echo "FAIL: paused=$PAUSED readyReplicas=$READY"
exit 1
