#!/bin/bash
set -euo pipefail
NS="k8smissions"
SUSPEND=$(kubectl get cronjob report-generator -n "$NS" -o jsonpath='{.spec.suspend}' 2>/dev/null || true)
if [ "$SUSPEND" = "false" ] || [ -z "$SUSPEND" ]; then
  echo "PASS: CronJob is no longer suspended"
  exit 0
fi
echo "FAIL: CronJob suspend=$SUSPEND"
exit 1
