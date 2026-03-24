#!/bin/bash
set -euo pipefail
NS="k8smissions"

PARAMS=$(kubectl get taskrun push-run -n "$NS" -o jsonpath='{.spec.params}' 2>/dev/null || true)

if [ -z "$PARAMS" ] || [ "$PARAMS" = "[]" ]; then
  echo "FAIL: TaskRun 'push-run' has no params — Task 'image-push' requires param IMAGE with no default"
  exit 1
fi

if echo "$PARAMS" | grep -q IMAGE; then
  echo "PASS: TaskRun 'push-run' supplies the required IMAGE param — TaskRun will pass validation"
  exit 0
fi

echo "FAIL: TaskRun 'push-run' params do not include required 'IMAGE' — add it under spec.params"
exit 1
