#!/bin/bash
set -euo pipefail
LABEL=$(kubectl get clusterrole deployments-reader     -o jsonpath='{.metadata.labels.rbac\.example\.io/aggregate-to-operator}' 2>/dev/null || true)
if [ "$LABEL" = "true" ]; then
  echo "PASS: Source ClusterRole has correct aggregation label"
  exit 0
fi
echo "FAIL: label rbac.example.io/aggregate-to-operator=$LABEL (expected true)"
exit 1
