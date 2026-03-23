#!/bin/bash
set -euo pipefail
NS="k8smissions"

# Check that the NetworkPolicy allows egress on port 53 (DNS)
PORT53=$(kubectl get networkpolicy deny-all-egress -n "$NS" \
  -o jsonpath='{.spec.egress[*].ports[*].port}' 2>/dev/null || true)

if echo "$PORT53" | grep -qw "53"; then
  echo "PASS: Egress rule allows DNS on port 53"
  exit 0
fi

echo "FAIL: No egress rule found for port 53 — pods cannot resolve DNS"
exit 1
