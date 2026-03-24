#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get pod init-pod -n k8smissions -o jsonpath='{.spec.initContainers[0].command}' 2>/dev/null | grep -qv 'non-existent'; then
  echo "PASS: Init Loop"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
