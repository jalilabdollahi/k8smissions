#!/bin/bash
set -euo pipefail
NS="k8smissions"

APPROVAL=$(kubectl get taskrun approval-gate -n "$NS" \
  -o jsonpath='{.metadata.annotations.awaiting-approval}' 2>/dev/null || true)

if [ "$APPROVAL" = "true" ]; then
  echo "FAIL: TaskRun 'approval-gate' annotation awaiting-approval=true — pipeline is still blocked; delete and recreate with auto-approve script"
  exit 1
fi

echo "PASS: TaskRun 'approval-gate' is not blocked (awaiting-approval='$APPROVAL') — pipeline can proceed"
exit 0
