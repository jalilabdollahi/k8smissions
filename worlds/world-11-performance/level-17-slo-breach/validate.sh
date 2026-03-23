#!/bin/bash
set -euo pipefail
NS="k8smissions"
THRESHOLD=$(kubectl get deployment slo-app -n k8smissions -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.failureThreshold}' 2>/dev/null || true)
if [ -n "$THRESHOLD" ] && [ "$THRESHOLD" != "10" ]; then
  echo "PASS: SLO Breach Alert"
  exit 0
fi
echo "FAIL: check broken configuration"
exit 1
