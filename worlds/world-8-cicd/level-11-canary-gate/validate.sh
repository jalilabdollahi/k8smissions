#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get rollout api-rollout -n k8smissions -o jsonpath='{.spec.strategy.canary.steps[3].pause.duration}' 2>/dev/null | grep -qv '^$'; then
  echo "PASS: Frozen Canary"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
