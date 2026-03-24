#!/bin/bash
set -euo pipefail
NS="k8smissions"
if ! kubectl get pod team-a-pod -n k8smissions -o jsonpath='{.spec.nodeSelector}' 2>/dev/null | grep -q team-a \
&& kubectl get deployment team-b-deploy -n k8smissions -o jsonpath='{.spec.template.spec.affinity.podAntiAffinity}' 2>/dev/null | grep -q preferred \
&& ! kubectl get pod team-c-pod -n k8smissions -o jsonpath='{.spec.priorityClassName}' 2>/dev/null | grep -q non-existent; then
  echo "PASS: Scheduler Overload"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
