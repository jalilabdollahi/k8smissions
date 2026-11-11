#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

# 1. the guard rail is still there and still bites
if ! kubectl get validatingadmissionpolicy require-run-as-non-root >/dev/null 2>&1 \
   || ! kubectl get validatingadmissionpolicybinding require-run-as-non-root >/dev/null 2>&1; then
  echo "❌ the require-run-as-non-root policy or its binding was removed"
  exit 1
fi
if ! kubectl get validatingadmissionpolicybinding require-run-as-non-root -o jsonpath='{.spec.validationActions}' | grep -q Deny; then
  echo "❌ the policy binding no longer denies"
  exit 1
fi
out=$(k run root-check --image=busybox:1.36 --dry-run=server -- sleep 1 2>&1)
if ! echo "$out" | grep -qi "runAsNonRoot"; then
  echo "❌ a plain root pod is no longer rejected in this namespace"
  exit 1
fi
echo "✅ the admission policy is intact and still rejects root pods"

# 2. the workload
if [ "$(k get deploy invoice-render -o jsonpath='{.spec.replicas}' 2>/dev/null)" != "2" ]; then
  echo "❌ Deployment invoice-render must exist with 2 replicas"
  exit 1
fi
if ! k rollout status deploy/invoice-render --timeout=45s >/dev/null 2>&1; then
  ready=$(k get deploy invoice-render -o jsonpath='{.status.readyReplicas}')
  echo "❌ invoice-render has ${ready:-0} of 2 replicas Ready"
  k get rs -l app=invoice-render -o jsonpath='{range .items[*]}{.status.conditions[?(@.type=="ReplicaFailure")].message}{"\n"}{end}' | head -c 300
  k get pods -l app=invoice-render --no-headers 2>/dev/null | awk '{print "   " $1 " " $2 " " $3}'
  exit 1
fi
pods=$(k get pods -l app=invoice-render --field-selector=status.phase=Running -o jsonpath='{.items[*].metadata.name}')
[ "$(echo $pods | wc -w)" -eq 2 ] || { echo "❌ expected 2 running invoice-render pods"; exit 1; }
for p in $pods; do
  if [ "$(k get pod "$p" -o jsonpath='{range .status.containerStatuses[*]}{.restartCount}{end}' | tr -d '0')" != "" ]; then
    echo "❌ $p has restarted"
    exit 1
  fi
done
echo "✅ 2 invoice-render pods Ready without restarts"

# 3. real UIDs
for p in $pods; do
  for c in web log-tail; do
    uid=$(k exec "$p" -c "$c" -- id -u 2>/dev/null)
    if [ -z "$uid" ] || [ "$uid" = "0" ]; then
      echo "❌ container $c of $p runs with UID '${uid:-?}'"
      exit 1
    fi
  done
done
echo "✅ both containers run with a non-zero UID"

# 4. it still works: a request is served and the sidecar sees it
p=$(echo $pods | cut -d' ' -f1)
mark="/validate-$$"
k exec "$p" -c web -- wget -qO- "http://127.0.0.1:8080$mark" >/dev/null 2>&1
sleep 1
if ! k logs "$p" -c log-tail --tail=20 2>/dev/null | grep -q "$mark"; then
  echo "❌ the log-tail sidecar does not see nginx requests"
  exit 1
fi
echo "✅ nginx serves and log-tail reads its access log"
exit 0
exit 1
