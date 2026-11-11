#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! kubectl get validatingwebhookconfiguration policy-guard >/dev/null 2>&1; then
  echo "❌ the policy-guard webhook configuration is gone; the guard has to stay in force"
  exit 1
fi
policies=$(kubectl get validatingwebhookconfiguration policy-guard -o jsonpath='{.webhooks[*].failurePolicy}')
notfail=$(echo "$policies" | tr ' ' '\n' | grep -vc '^Fail$')
if [ -z "$policies" ] || [ "$notfail" != 0 ]; then
  echo "❌ policy-guard no longer fails closed (failurePolicy: ${policies:-unset})"
  exit 1
fi
echo "✅ policy-guard exists and fails closed"

pod() {  # pod <image>: server-side dry-run of a guarded pod
  k create --dry-run=server -f - 2>&1 <<Y
apiVersion: v1
kind: Pod
metadata: {name: probe-guarded, labels: {guarded: "true"}}
spec:
  containers:
  - {name: c, image: "$1", command: ["sleep", "5"]}
Y
}

good=$(pod nginx:1.27-alpine)
if ! echo "$good" | grep -q 'created (server dry run)'; then
  echo "❌ a compliant guarded pod is refused: $(echo "$good" | head -c 260)"
  exit 1
fi
echo "✅ a compliant guarded pod is admitted"

bad=$(pod nginx:latest)
if echo "$bad" | grep -q 'created (server dry run)'; then
  echo "❌ a guarded pod using nginx:latest was admitted: the guard is not enforcing"
  exit 1
fi
if ! echo "$bad" | grep -q 'policy-guard: image'; then
  echo "❌ a guarded pod using nginx:latest is refused, but not by the policy: $(echo "$bad" | head -c 260)"
  exit 1
fi
echo "✅ a guarded pod using nginx:latest is rejected by the policy"
exit 0
exit 1
