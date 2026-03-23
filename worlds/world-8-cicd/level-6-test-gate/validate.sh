#!/bin/bash
set -euo pipefail
NS="k8smissions"

SCRIPT=$(kubectl get task run-tests -n "$NS" -o jsonpath='{.spec.steps[0].script}' 2>/dev/null || true)

if echo "$SCRIPT" | grep -q 'exit 0'; then
  echo "PASS: Task 'run-tests' test script exits with 0 — test gate passes and deploy stage is unblocked"
  exit 0
fi

echo "FAIL: Task 'run-tests' script does not exit 0 — fix the test command or change exit 1 to exit 0"
exit 1
