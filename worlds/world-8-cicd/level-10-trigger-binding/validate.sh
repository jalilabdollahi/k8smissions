#!/bin/bash
set -euo pipefail
NS="k8smissions"

GIT_REV_VALUE=$(kubectl get triggerbinding git-push-binding -n "$NS" \
  -o jsonpath='{.spec.params[0].value}' 2>/dev/null || true)

if echo "$GIT_REV_VALUE" | grep -q head_commit; then
  echo "PASS: TriggerBinding uses '\$(body.head_commit.id)' — correct GitHub push webhook field for commit SHA"
  exit 0
fi

echo "FAIL: TriggerBinding git-revision value is '$GIT_REV_VALUE' — should be '\$(body.head_commit.id)' not '\$(body.commits[0].sha)'"
exit 1
