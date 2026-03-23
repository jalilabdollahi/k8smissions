#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get deployment distributed-app -n k8smissions -o jsonpath='{.spec.template.spec.affinity.podAntiAffinity}' 2>/dev/null | grep -q preferred; then
  echo "PASS: Anti-Affinity Trap"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
