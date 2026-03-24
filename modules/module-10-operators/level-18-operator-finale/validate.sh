#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get validatingwebhookconfiguration strict-validator -o jsonpath='{.webhooks[0].failurePolicy}' 2>/dev/null | grep -q Ignore \
&& kubectl get crd apps.example.com -o jsonpath='{.spec.versions[*].name}' 2>/dev/null | grep -q v1 \
&& kubectl get deployment my-operator -n operators -o jsonpath='{.spec.template.spec.containers[0].args}' 2>/dev/null | grep -q 'leader-elect=true'; then
  echo "PASS: Operator Meltdown"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
