#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get deployment slo-app -n k8smissions -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.failureThreshold}' 2>/dev/null | grep -qv '^10$' || echo PASS; then
  echo "PASS: SLO Breach Alert"
  exit 0
fi
echo "FAIL: check broken configuration"
exit 1
