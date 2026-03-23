#!/bin/bash
set -euo pipefail
NS="k8smissions"

WS=$(kubectl get taskrun build-cache-run -n "$NS" -o jsonpath='{.spec.workspaces}' 2>/dev/null || true)

if echo "$WS" | grep -q cache; then
  echo "PASS: TaskRun 'build-cache-run' has a 'cache' workspace binding — Maven deps are cached between runs"
  exit 0
fi

echo "FAIL: TaskRun 'build-cache-run' is missing the 'cache' workspace binding — add a PVC binding for the maven-build Task's cache workspace"
exit 1
