#!/bin/bash
set -euo pipefail
NS="k8smissions"

SYNC=$(kubectl get configmap node-clock-status -n "$NS" -o jsonpath='{.data.ntp_sync}' 2>/dev/null || true)
SKEW=$(kubectl get configmap node-clock-status -n "$NS" -o jsonpath='{.data.skew_seconds}' 2>/dev/null || true)
if [ "$SYNC" = "true" ] && [ "$SKEW" = "0" ]; then
  echo "✅ PASS: Node clock is synced with zero skew"
  exit 0
fi
echo "❌ FAIL: ntp_sync='$SYNC' skew='$SKEW'"
exit 1
