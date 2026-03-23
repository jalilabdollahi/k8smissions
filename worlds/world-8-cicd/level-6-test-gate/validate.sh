#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get task run-tests -n k8smissions -o jsonpath='{.spec.steps[0].script}' 2>/dev/null | grep -q 'exit 0'; then
  echo "PASS: Gate Blocks Deploy"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
