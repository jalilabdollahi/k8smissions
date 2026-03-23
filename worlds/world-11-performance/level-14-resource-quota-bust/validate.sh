#!/bin/bash
set -euo pipefail
NS="k8smissions"
CPU_QUOTA=$(kubectl get resourcequota compute-resources -n k8smissions -o jsonpath='{.spec.hard.requests\.cpu}' 2>/dev/null || true)
if [ -n "$CPU_QUOTA" ] && [ "$CPU_QUOTA" != "4" ]; then
  echo "PASS: Namespace Full"
  exit 0
fi
echo "FAIL: check broken configuration"
exit 1
