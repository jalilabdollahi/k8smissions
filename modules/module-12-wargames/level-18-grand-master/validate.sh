#!/bin/bash
set -euo pipefail
NS="k8smissions"

FAIL=0

# W1: pod image — must not be the broken tag
IMG=$(kubectl get pod w1-pod -n "$NS" -o jsonpath='{.spec.containers[0].image}' 2>/dev/null || true)
[ "$IMG" = "nginx:doesnotexist99" ] && echo "❌ W1: pod still has bad image (nginx:doesnotexist99)" && FAIL=1

# W2: deployment replicas — must not be 0
R=$(kubectl get deploy w2-deploy -n "$NS" -o jsonpath='{.spec.replicas}' 2>/dev/null || true)
[ "$R" = "0" ] && echo "❌ W2: deployment w2-deploy still at 0 replicas" && FAIL=1

# W3: service selector — must not point to wrong-label
SEL=$(kubectl get svc w3-svc -n "$NS" -o jsonpath='{.spec.selector.app}' 2>/dev/null || true)
[ "$SEL" = "wrong-label" ] && echo "❌ W3: service w3-svc selector not fixed (still wrong-label)" && FAIL=1

# W4: PVC storage — must not be the impossible size
PVC=$(kubectl get pvc w4-pvc -n "$NS" -o jsonpath='{.spec.resources.requests.storage}' 2>/dev/null || true)
[ "$PVC" = "500Ti" ] && echo "❌ W4: PVC w4-pvc still has impossible storage request (500Ti)" && FAIL=1

# W5: rolebinding must exist
kubectl get rolebinding w5-rb -n "$NS" >/dev/null 2>&1 || { echo "❌ W5: RoleBinding w5-rb is missing"; FAIL=1; }

# W6: readiness probe must be configured
PROBE=$(kubectl get deploy w6-monitored -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.path}' 2>/dev/null || true)
[ -z "$PROBE" ] && echo "❌ W6: w6-monitored readiness probe is missing" && FAIL=1

# W7: ConfigMap values must not be empty
ENV=$(kubectl get cm w7-config -n "$NS" -o jsonpath='{.data.ENV}' 2>/dev/null || true)
[ -z "$ENV" ] && echo "❌ W7: ConfigMap w7-config ENV is still empty" && FAIL=1

# W8: secret must exist
kubectl get secret w8-secret -n "$NS" >/dev/null 2>&1 || { echo "❌ W8: Secret w8-secret is missing"; FAIL=1; }

# W9: memory limit must not be the dangerously low value
MEM=$(kubectl get deploy w9-scheduled -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null || true)
[ "$MEM" = "1Mi" ] && echo "❌ W9: w9-scheduled memory limit still 1Mi (too low — OOMKill storm)" && FAIL=1

# W10: w10-operator command must not be the always-crashing one
CMD=$(kubectl get deploy w10-operator -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].command[2]}' 2>/dev/null || true)
[ "$CMD" = "exit 1" ] && echo "❌ W10: w10-operator command still 'exit 1' — CrashLoopBackOff" && FAIL=1

# W11: PDB minAvailable must be less than replica count (not > replicas)
W11_MIN=$(kubectl get pdb w11-pdb -n "$NS" -o jsonpath='{.spec.minAvailable}' 2>/dev/null || true)
W11_REP=$(kubectl get deploy w11-perf -n "$NS" -o jsonpath='{.spec.replicas}' 2>/dev/null || true)
if [ -n "$W11_MIN" ] && [ -n "$W11_REP" ]; then
  [ "$W11_MIN" -ge "$W11_REP" ] 2>/dev/null && echo "❌ W11: PDB w11-pdb minAvailable ($W11_MIN) >= replicas ($W11_REP) — drain still blocked" && FAIL=1
fi

# W12: failover ConfigMap must have failover enabled and sync healthy
W12_FO=$(kubectl get cm w12-failover -n "$NS" -o jsonpath='{.data.failover-enabled}' 2>/dev/null || true)
W12_SS=$(kubectl get cm w12-failover -n "$NS" -o jsonpath='{.data.sync-status}' 2>/dev/null || true)
[ "$W12_FO" != "true" ] && echo "❌ W12: w12-failover ConfigMap failover-enabled is not 'true'" && FAIL=1
[ "$W12_SS" != "synced" ] && echo "❌ W12: w12-failover ConfigMap sync-status is not 'synced'" && FAIL=1

if [ "$FAIL" = "0" ]; then
  echo "✅ PASS: All 12 module failures resolved — GRAND MASTER ACHIEVED"
  exit 0
fi
exit 1
