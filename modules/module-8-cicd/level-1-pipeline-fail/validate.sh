#!/bin/bash
set -euo pipefail
NS="k8smissions"

IMAGE=$(kubectl get task build-task -n "$NS" -o jsonpath='{.spec.steps[0].image}' 2>/dev/null || true)

if [ -z "$IMAGE" ]; then
  echo "FAIL: Task 'build-task' not found in namespace $NS"
  exit 1
fi

if echo "$IMAGE" | grep -q '99\.9'; then
  echo "FAIL: Task image is '$IMAGE' — tag '99.9-nonexistent' does not exist; change to a valid tag like golang:1.21"
  exit 1
fi

echo "PASS: Task image is '$IMAGE' — valid image tag will allow the pipeline step to start"
exit 0
