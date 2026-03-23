#!/bin/bash
set -euo pipefail
NS="k8smissions"

WS=$(kubectl get pipelinerun build-run -n "$NS" -o jsonpath='{.spec.workspaces}' 2>/dev/null || true)

if [ -z "$WS" ] || [ "$WS" = "[]" ]; then
  echo "FAIL: PipelineRun 'build-run' has no workspace bindings — add a binding for the 'source' workspace"
  exit 1
fi

if echo "$WS" | grep -q source; then
  echo "PASS: PipelineRun 'build-run' has a 'source' workspace binding — pipeline can proceed"
  exit 0
fi

echo "FAIL: PipelineRun 'build-run' workspace bindings do not include 'source' — Pipeline requires a workspace named 'source'"
exit 1
