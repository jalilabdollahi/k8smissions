#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! kubectl get validatingwebhookconfiguration quota-guard >/dev/null 2>&1; then
  echo "❌ the quota-guard webhook configuration is gone; the quota has to stay enforced"
  exit 1
fi
policies=$(kubectl get validatingwebhookconfiguration quota-guard -o jsonpath='{.webhooks[*].failurePolicy}')
if [ -z "$policies" ] || [ "$(echo "$policies" | tr ' ' '\n' | grep -vc '^Fail$')" != 0 ]; then
  echo "❌ quota-guard no longer fails closed (failurePolicy: ${policies:-unset})"
  exit 1
fi
for d in quota-guard asset-inventory; do
  r=$(k get deploy $d -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
  if [ "${r:-0}" -lt 1 ]; then
    echo "❌ Deployment $d has no ready pod"
    exit 1
  fi
done
echo "✅ quota-guard fails closed and both of its Deployments are running"

pod() {  # pod <cpu>: server-side dry-run of a guarded pod of team payments
  k create --dry-run=server -f - 2>&1 <<Y
apiVersion: v1
kind: Pod
metadata: {name: probe-guarded, labels: {guarded: "true", team: payments}}
spec:
  containers:
  - name: c
    image: busybox:1.36
    command: ["sleep", "5"]
    resources: {requests: {cpu: $1}}
Y
}

start=$(date +%s)
good=$(pod 100m)
took=$(( $(date +%s) - start ))
if ! echo "$good" | grep -q 'created (server dry run)'; then
  echo "❌ a compliant guarded pod is refused: $(echo "$good" | head -c 260)"
  exit 1
fi
if [ "$took" -gt 3 ]; then
  echo "❌ a compliant guarded pod is admitted, but only after ${took}s (target: under 3s)"
  exit 1
fi
echo "✅ a compliant guarded pod is admitted in ${took}s"

bad=$(pod 4000m)
if echo "$bad" | grep -q 'created (server dry run)'; then
  echo "❌ a guarded pod asking for 4000m CPU (quota 500m) was admitted: the quota is not enforced"
  exit 1
fi
if ! echo "$bad" | grep -q 'quota-guard: team payments'; then
  echo "❌ the over-quota pod is refused, but not by the quota policy: $(echo "$bad" | head -c 260)"
  exit 1
fi
echo "✅ an over-quota guarded pod is rejected by the policy"
exit 0
exit 1
