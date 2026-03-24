#!/bin/bash
set -euo pipefail
NS="k8smissions"

IMAGE=$(kubectl get rollout web-rollout -n "$NS" \
  -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)

if echo "$IMAGE" | grep -q 'bad-tag'; then
  echo "FAIL: Rollout 'web-rollout' still uses '$IMAGE' — 'bad-tag' does not exist; fix the image and retry with: kubectl argo rollouts retry rollout web-rollout"
  exit 1
fi

echo "PASS: Rollout 'web-rollout' image is '$IMAGE' (not bad-tag) — retry the rollout to recover from Degraded state"
exit 0
