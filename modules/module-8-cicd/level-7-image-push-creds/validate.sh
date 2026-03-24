#!/bin/bash
set -euo pipefail
NS="k8smissions"

SECRETS=$(kubectl get serviceaccount ci-sa -n "$NS" -o jsonpath='{.secrets}' 2>/dev/null || true)

if echo "$SECRETS" | grep -q registry; then
  echo "PASS: ServiceAccount 'ci-sa' has registry credentials — image push will authenticate successfully"
  exit 0
fi

echo "FAIL: ServiceAccount 'ci-sa' has no registry credentials (current secrets: $SECRETS) — create a docker-registry secret and attach it to ci-sa"
exit 1
