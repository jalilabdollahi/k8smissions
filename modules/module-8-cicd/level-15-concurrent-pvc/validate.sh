#!/bin/bash
set -euo pipefail
NS="k8smissions"

# Check if the most recent PipelineRun uses volumeClaimTemplate (per-run isolation) instead of a shared PVC
LATEST_RUN=$(kubectl get pipelinerun -n "$NS" --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.name}' 2>/dev/null || true)

if [ -z "$LATEST_RUN" ]; then
  echo "FAIL: No PipelineRuns found in namespace $NS"
  exit 1
fi

VCT=$(kubectl get pipelinerun "$LATEST_RUN" -n "$NS" -o jsonpath='{.spec.workspaces[0].volumeClaimTemplate}' 2>/dev/null || true)

if [ -n "$VCT" ]; then
  echo "PASS: PipelineRun '$LATEST_RUN' uses volumeClaimTemplate — each run gets an isolated PVC"
  exit 0
fi

echo "FAIL: PipelineRun '$LATEST_RUN' does not use volumeClaimTemplate — concurrent runs may share a PVC and corrupt each other's artifacts"
exit 1
