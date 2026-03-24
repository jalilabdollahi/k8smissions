#!/bin/bash
set -euo pipefail
NS="k8smissions"

RESULT=$(kubectl auth can-i create pipelineruns.tekton.dev -n "$NS" \
  --as=system:serviceaccount:${NS}:trigger-sa 2>/dev/null || true)

if [ "$RESULT" = "yes" ]; then
  echo "PASS: ServiceAccount 'trigger-sa' can create PipelineRuns — EventListener can trigger pipelines on webhook events"
  exit 0
fi

echo "FAIL: ServiceAccount 'trigger-sa' cannot create pipelineruns.tekton.dev — create a Role targeting apiGroups: [tekton.dev] and bind it to trigger-sa"
exit 1
