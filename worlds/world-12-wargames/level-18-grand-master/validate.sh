#!/bin/bash
set -euo pipefail
NS="k8smissions"

FAIL=0
# W1: pod image
IMG=$(kubectl get pod w1-pod -n "$NS" -o jsonpath='{.spec.containers[0].image}' 2>/dev/null || true)
[ "$IMG" = "nginx:doesnotexist99" ] && echo "❌ W1: pod still has bad image" && FAIL=1

# W2: deployment replicas
R=$(kubectl get deploy w2-deploy -n "$NS" -o jsonpath='{.spec.replicas}' 2>/dev/null || true)
[ "$R" = "0" ] && echo "❌ W2: deployment still at 0 replicas" && FAIL=1

# W3: service selector
SEL=$(kubectl get svc w3-svc -n "$NS" -o jsonpath='{.spec.selector.app}' 2>/dev/null || true)
[ "$SEL" = "wrong-label" ] && echo "❌ W3: service selector not fixed" && FAIL=1

# W4: PVC storage
PVC=$(kubectl get pvc w4-pvc -n "$NS" -o jsonpath='{.spec.resources.requests.storage}' 2>/dev/null || true)
[ "$PVC" = "500Ti" ] && echo "❌ W4: PVC still has impossible storage request" && FAIL=1

# W5: rolebinding
kubectl get rolebinding w5-rb -n "$NS" >/dev/null 2>&1 || { echo "❌ W5: RoleBinding w5-rb missing"; FAIL=1; }

# W6: readiness probe
PROBE=$(kubectl get deploy w6-monitored -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.path}' 2>/dev/null || true)
[ -z "$PROBE" ] && echo "❌ W6: readiness probe missing" && FAIL=1

# W7: configmap values
ENV=$(kubectl get cm w7-config -n "$NS" -o jsonpath='{.data.ENV}' 2>/dev/null || true)
[ -z "$ENV" ] && echo "❌ W7: ConfigMap ENV still empty" && FAIL=1

# W8: secret
kubectl get secret w8-secret -n "$NS" >/dev/null 2>&1 || { echo "❌ W8: Secret w8-secret missing"; FAIL=1; }

# W9: memory limit
MEM=$(kubectl get deploy w9-scheduled -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null || true)
[ "$MEM" = "1Mi" ] && echo "❌ W9: Memory limit still 1Mi (too low)" && FAIL=1

if [ "$FAIL" = "0" ]; then
  echo "✅ PASS: All 9 world failures resolved — GRAND MASTER ACHIEVED"
  exit 0
fi
exit 1
