#!/bin/bash
set -euo pipefail
NS="k8smissions"

# Check that the deploy task's IMAGE_DIGEST param references the correct result name (camelCase 'imageDigest')
RESULT_REF=$(kubectl get pipeline build-deploy -n "$NS" \
  -o jsonpath='{.spec.tasks[1].params[0].value}' 2>/dev/null || true)

if echo "$RESULT_REF" | grep -q 'imageDigest'; then
  echo "PASS: Pipeline 'build-deploy' deploy task references '\$(tasks.build.results.imageDigest)' — correct camelCase result name"
  exit 0
fi

echo "FAIL: Pipeline deploy task IMAGE_DIGEST value is '$RESULT_REF' — should be '\$(tasks.build.results.imageDigest)' not '\$(tasks.build.results.image-digest)'"
exit 1
