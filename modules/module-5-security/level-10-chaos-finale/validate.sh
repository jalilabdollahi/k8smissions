#!/bin/bash
S=settle
k() { kubectl -n "$S" "$@"; }
can() { kubectl auth can-i "$@" -n "$S" --as="system:serviceaccount:$S:settlement" 2>/dev/null; }

if ! kubectl get ns "$S" >/dev/null 2>&1; then
  echo "❌ namespace $S does not exist"
  exit 1
fi

# 1. the guard rails stay
if [ "$(kubectl get ns "$S" -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}')" != "restricted" ]; then
  echo "❌ namespace $S no longer enforces the restricted Pod Security level"
  exit 1
fi
out=$(k run priv-check --image=busybox:1.36 --privileged --dry-run=server -- sleep 1 2>&1)
if ! echo "$out" | grep -q "violates PodSecurity"; then
  echo "❌ a privileged pod is no longer rejected in $S"
  exit 1
fi
if ! k get quota settle-quota -o json 2>/dev/null | jq -e '.spec.hard["limits.cpu"]=="2" and .spec.hard["limits.memory"]=="2Gi"' >/dev/null; then
  echo "❌ quota settle-quota is missing or its limits were changed"
  exit 1
fi
echo "✅ restricted Pod Security and quota settle-quota are intact"

# 2. RBAC: allowed and forbidden
if [ "$(can get configmap/settle-config)" != "yes" ]; then
  echo "❌ ServiceAccount settlement cannot get ConfigMap settle-config"
  exit 1
fi
for no in "get secrets" "list secrets" "create pods" "delete configmaps" "update configmaps" "create rolebindings"; do
  if [ "$(can $no)" = "yes" ]; then
    echo "❌ settlement is too powerful: it can $no"
    exit 1
  fi
done
if [ "$(kubectl auth can-i get configmaps -n kube-system --as="system:serviceaccount:$S:settlement" 2>/dev/null)" = "yes" ] || \
   [ "$(kubectl auth can-i '*' '*' --as="system:serviceaccount:$S:settlement" 2>/dev/null)" = "yes" ]; then
  echo "❌ settlement has access outside its namespace"
  exit 1
fi
echo "✅ settlement reads its ConfigMap and nothing sensitive"

# 3. the workload
if [ "$(k get deploy settlement -o jsonpath='{.spec.replicas}' 2>/dev/null)" != "2" ]; then
  echo "❌ Deployment settlement must exist with 2 replicas"
  exit 1
fi
if ! k rollout status deploy/settlement --timeout=50s >/dev/null 2>&1; then
  ready=$(k get deploy settlement -o jsonpath='{.status.readyReplicas}')
  echo "❌ settlement has ${ready:-0} of 2 pods Ready"
  k get rs -l app=settlement -o jsonpath='{range .items[*]}{.status.conditions[?(@.type=="ReplicaFailure")].message}{"\n"}{end}' | head -c 300
  exit 1
fi
pods=$(k get pods -l app=settlement --field-selector=status.phase=Running -o jsonpath='{.items[*].metadata.name}')
for p in $pods; do
  if [ "$(k get pod "$p" -o jsonpath='{.status.containerStatuses[0].restartCount}')" != "0" ]; then
    echo "❌ $p has restarted"
    exit 1
  fi
done
body=$(kubectl get --raw "/api/v1/namespaces/$S/services/settlement:8080/proxy/ready" 2>&1)
if ! echo "$body" | grep -q "db=ok"; then
  echo "❌ /ready does not answer 200: $(echo "$body" | head -c 160)"
  exit 1
fi
echo "✅ settlement /ready answers 200: $(echo "$body" | head -1)"

# 4. the database is closed to everyone else
if k exec rogue -- wget -q -T 3 -O /dev/null http://settle-db:5432/ >/dev/null 2>&1; then
  echo "❌ pod rogue can still reach settle-db"
  exit 1
fi
echo "✅ settle-db answers settlement and still refuses rogue"
exit 0
exit 1
