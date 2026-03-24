#!/bin/bash
set -euo pipefail
NS="k8smissions"

# steps[3] is the 4th step (0-indexed): the pause:{} step that becomes pause:{duration: 5m}
DURATION=$(kubectl get rollout api-rollout -n "$NS" \
  -o jsonpath='{.spec.strategy.canary.steps[3].pause.duration}' 2>/dev/null || true)

if [ -n "$DURATION" ]; then
  echo "PASS: Canary pause step has duration='$DURATION' — rollout will auto-promote after the specified time"
  exit 0
fi

echo "FAIL: Canary pause step[3] has no duration — pause: {} waits forever for manual promotion; set pause.duration (e.g. 5m) or use 'kubectl argo rollouts promote'"
exit 1
