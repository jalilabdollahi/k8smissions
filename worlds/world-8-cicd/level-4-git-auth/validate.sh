#!/bin/bash
set -euo pipefail
NS="k8smissions"

SECRETS=$(kubectl get serviceaccount pipeline-sa -n "$NS" -o jsonpath='{.secrets}' 2>/dev/null || true)

if echo "$SECRETS" | grep -q git-ssh; then
  echo "PASS: ServiceAccount 'pipeline-sa' has 'git-ssh' secret attached — git-clone Task can authenticate to the private repo"
  exit 0
fi

echo "FAIL: ServiceAccount 'pipeline-sa' has no git-ssh secret (current secrets: $SECRETS) — create an SSH secret and attach it to the SA"
exit 1
