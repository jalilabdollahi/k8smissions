#!/bin/bash
set -euo pipefail
NS="k8smissions"

# This level teaches Helm values indentation. The fix is applied via helm upgrade.
# We check that the deployed pod is running the correct image tag (v2.0.0).
IMAGE=$(kubectl get deployment helm-app -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)

if [ -z "$IMAGE" ]; then
  echo "FAIL: Deployment 'helm-app' not found in namespace $NS"
  exit 1
fi

if echo "$IMAGE" | grep -q "v2.0.0"; then
  echo "PASS: Deployment image is $IMAGE — Helm values.yaml indentation is correct"
  exit 0
fi

echo "FAIL: Deployment image is '$IMAGE' (expected tag v2.0.0) — check image.tag indentation in values.yaml"
exit 1
