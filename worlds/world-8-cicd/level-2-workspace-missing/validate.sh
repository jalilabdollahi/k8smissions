#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get pipelinerun build-run -n k8smissions -o jsonpath='{.spec.workspaces}' 2>/dev/null | grep -q source; then
  echo "PASS: No Workspace"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
