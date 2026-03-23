#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get pipeline build-deploy -n k8smissions -o jsonpath='{.spec.tasks[1].params[0].value}' 2>/dev/null | grep -q imageDigest; then
  echo "PASS: Lost Artifact"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
