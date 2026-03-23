#!/bin/bash
set -euo pipefail
NS="k8smissions"

RESULT=$(kubectl auth can-i create deployments -n "$NS" \
  --as=system:serviceaccount:${NS}:deploy-sa 2>/dev/null || true)

if [ "$RESULT" = "yes" ]; then
  echo "PASS: ServiceAccount 'deploy-sa' can create Deployments — pipeline deploy Task will succeed"
  exit 0
fi

echo "FAIL: ServiceAccount 'deploy-sa' cannot create Deployments — create a Role with deploy permissions and bind it to deploy-sa"
exit 1
