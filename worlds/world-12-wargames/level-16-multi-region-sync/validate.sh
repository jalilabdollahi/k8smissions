#!/bin/bash
set -euo pipefail
NS="k8smissions"

ENABLED=$(kubectl get configmap leader-election -n "$NS" -o jsonpath='{.data.failover-enabled}' 2>/dev/null || true)
STATUS=$(kubectl get configmap leader-election -n "$NS" -o jsonpath='{.data.sync-status}' 2>/dev/null || true)
if [ "$ENABLED" = "true" ] && [ "$STATUS" = "synced" ]; then
  echo "✅ PASS: Failover is enabled and sync status is healthy"
  exit 0
fi
echo "❌ FAIL: failover-enabled='$ENABLED' sync-status='$STATUS'"
exit 1
