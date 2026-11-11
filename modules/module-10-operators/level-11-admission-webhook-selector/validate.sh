#!/bin/bash
WH=pod-labeler

if ! kubectl get mutatingwebhookconfiguration $WH >/dev/null 2>&1; then
  echo "❌ the $WH webhook configuration is gone; pods in shop must still be labelled"
  exit 1
fi
policies=$(kubectl get mutatingwebhookconfiguration $WH -o jsonpath='{.webhooks[*].failurePolicy}')
if [ -z "$policies" ] || [ "$(echo "$policies" | tr ' ' '\n' | grep -vc '^Fail$')" != 0 ]; then
  echo "❌ $WH no longer fails closed (failurePolicy: ${policies:-unset})"
  exit 1
fi
echo "✅ the $WH webhook exists and fails closed"

ready=$(kubectl -n labeler-system get deploy pod-labeler -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -lt 1 ]; then
  echo "❌ the pod-labeler server has no ready pod in labeler-system (${ready:-0} of 1)"
  exit 1
fi
echo "✅ the pod-labeler server is running"

probe() {  # probe <namespace>: labels a new pod would get, after admission
  kubectl -n "$1" run probe-labels --image=busybox:1.36 --restart=Never --dry-run=server \
    -o jsonpath='{.metadata.labels}' 2>&1
}

shop=$(probe shop)
if ! echo "$shop" | grep -q '"labeler/injected":"true"'; then
  echo "❌ a new pod in shop is not labelled labeler/injected=true: $(echo "$shop" | head -c 240)"
  exit 1
fi
echo "✅ pods in shop are mutated"

sys=$(probe labeler-system)
if echo "$sys" | grep -qi 'error\|denied\|webhook'; then
  echo "❌ a pod in labeler-system is refused: $(echo "$sys" | head -c 240)"
  exit 1
fi
if echo "$sys" | grep -q 'labeler/injected'; then
  echo "❌ a pod in labeler-system is mutated too; the labeler must leave its own namespace alone"
  exit 1
fi
echo "✅ pods in labeler-system are admitted untouched"
exit 0
exit 1
