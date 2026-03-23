#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get pod dns-pod -n k8smissions -o jsonpath='{.spec.dnsConfig}' 2>/dev/null | grep -q ndots \
&& kubectl get deployment throttled-api -n k8smissions -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}' 2>/dev/null | grep -qv '^200m$' \
&& kubectl get deployment slow-rollout -n k8smissions -o jsonpath='{.spec.strategy.rollingUpdate.maxSurge}' 2>/dev/null | grep -qv '^0$'; then
  echo "PASS: The Great Slowdown"
  exit 0
fi
echo "FAIL: check broken configuration"
exit 1
