#!/bin/bash
set -euo pipefail
NS="k8smissions"
DESIRED=$(kubectl get daemonset log-collector -n "$NS" -o jsonpath='{.status.desiredNumberScheduled}' 2>/dev/null || true)
READY=$(kubectl get daemonset log-collector -n "$NS" -o jsonpath='{.status.numberReady}' 2>/dev/null || true)
if [ -n "$DESIRED" ] && [ "$DESIRED" = "$READY" ] && [ "$DESIRED" -gt 0 ]; then
  echo "PASS: DaemonSet has $READY/$DESIRED pods ready"
  exit 0
fi
echo "FAIL: DaemonSet desired=$DESIRED ready=$READY"
exit 1
