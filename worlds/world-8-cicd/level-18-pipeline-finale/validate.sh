#!/bin/bash
set -euo pipefail
NS="k8smissions"

PASS=true

# Fix 1: Check image tag is not the broken '999' tag
IMAGE=$(kubectl get task multi-task -n "$NS" -o jsonpath='{.spec.steps[0].image}' 2>/dev/null || true)
if echo "$IMAGE" | grep -q '999'; then
  echo "FAIL [1/3]: Task image is '$IMAGE' — change alpine/git:999 to a valid tag like alpine/git:latest"
  PASS=false
else
  echo "PASS [1/3]: Task image is '$IMAGE' (not :999)"
fi

# Fix 2: Check git-url param has a default value
GIT_URL_DEFAULT=$(kubectl get task multi-task -n "$NS" \
  -o jsonpath='{.spec.params[?(@.name=="git-url")].default}' 2>/dev/null || true)
if [ -z "$GIT_URL_DEFAULT" ]; then
  echo "FAIL [2/3]: param 'git-url' has no default — TaskRun will fail validation if git-url is not supplied"
  PASS=false
else
  echo "PASS [2/3]: param 'git-url' has default='$GIT_URL_DEFAULT'"
fi

# Fix 3: Check SA can create taskruns
RBAC=$(kubectl auth can-i create taskruns.tekton.dev -n "$NS" \
  --as=system:serviceaccount:${NS}:multi-sa 2>/dev/null || true)
if [ "$RBAC" != "yes" ]; then
  echo "FAIL [3/3]: ServiceAccount 'multi-sa' cannot create taskruns — add Role and RoleBinding"
  PASS=false
else
  echo "PASS [3/3]: ServiceAccount 'multi-sa' can create taskruns"
fi

if [ "$PASS" = "true" ]; then
  echo "PASS: All three pipeline issues resolved — pipeline is fully operational"
  exit 0
fi

echo "FAIL: One or more pipeline issues remain — fix all three before the pipeline can run"
exit 1
