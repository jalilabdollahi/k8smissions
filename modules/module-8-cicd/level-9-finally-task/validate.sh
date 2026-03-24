#!/bin/bash
set -euo pipefail
NS="k8smissions"

FINALLY=$(kubectl get pipeline build-and-clean -n "$NS" -o jsonpath='{.spec.finally}' 2>/dev/null || true)

if echo "$FINALLY" | grep -q cleanup; then
  echo "PASS: Pipeline 'build-and-clean' has 'cleanup' in spec.finally — cleanup runs unconditionally on success or failure"
  exit 0
fi

echo "FAIL: Pipeline 'build-and-clean' spec.finally does not contain 'cleanup' — move the cleanup task from spec.tasks to spec.finally"
exit 1
