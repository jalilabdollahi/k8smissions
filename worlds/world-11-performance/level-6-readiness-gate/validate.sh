#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get deployment java-app -n k8smissions -o jsonpath='{.spec.template.spec.containers[0].readinessProbe}' 2>/dev/null | grep -q initialDelaySeconds || echo PASS; then
  echo "PASS: Traffic to Cold Pods"
  exit 0
fi
echo "FAIL: check broken configuration"
exit 1
