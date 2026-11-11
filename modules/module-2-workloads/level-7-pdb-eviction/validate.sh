#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get deploy ledger-api >/dev/null 2>&1; then
  echo "❌ Deployment ledger-api does not exist"
  exit 1
fi
if ! k get pdb ledger-api-pdb >/dev/null 2>&1; then
  echo "❌ PodDisruptionBudget ledger-api-pdb does not exist"
  exit 1
fi
if ! k rollout status deploy/ledger-api --timeout=40s >/dev/null 2>&1; then
  echo "❌ ledger-api is not fully available"
  exit 1
fi
want=$(k get deploy ledger-api -o jsonpath='{.spec.replicas}')
if [ "${want:-0}" -lt 2 ]; then
  echo "❌ ledger-api runs with $want replica(s); the ledger must stay redundant"
  exit 1
fi

node=$(k get pods -l app=ledger-api -o jsonpath='{.items[0].spec.nodeName}')
if [ -z "$node" ]; then
  echo "❌ no ledger-api pod is scheduled"
  exit 1
fi
echo "draining $node (up to 50 seconds) while polling the Service..."

cleanup() { kubectl uncordon "$node" >/dev/null 2>&1; }
trap cleanup EXIT

k exec deploy/probe -- sh -c 'rm -f /tmp/res; for i in $(seq 100); do curl -s --max-time 1 -o /dev/null -w "%{http_code}\n" http://ledger-api >> /tmp/res; sleep 0.5; done' >/dev/null 2>&1 &
poller=$!
kubectl drain "$node" --ignore-daemonsets --delete-emptydir-data --pod-selector=app=ledger-api --timeout=50s >/tmp/k8sm-drain.$$ 2>&1
drc=$?
kill $poller 2>/dev/null; wait $poller 2>/dev/null
out=$(k exec deploy/probe -- cat /tmp/res 2>/dev/null)
total=$(echo "$out" | grep -c .)
bad=$(echo "$out" | grep -vc '^200$')
rm -f /tmp/k8sm-drain.$$

if [ "$drc" -ne 0 ]; then
  echo "❌ the drain of $node did not finish within 50 seconds"
  exit 1
fi
echo "✅ node $node drained"
if [ "$total" -lt 10 ]; then
  echo "❌ could not collect enough samples from the Service ($total)"
  exit 1
fi
if [ "$bad" -ne 0 ]; then
  echo "❌ ledger-api: $bad of $total requests failed during the drain"
  exit 1
fi
echo "✅ ledger-api: $total of $total requests succeeded during the drain"

kubectl uncordon "$node" >/dev/null 2>&1
if ! k rollout status deploy/ledger-api --timeout=60s >/dev/null 2>&1; then
  echo "❌ ledger-api did not come back to full strength"
  exit 1
fi
echo "✅ ledger-api is fully available again"

# The PDB must still protect the Deployment (selector matches the pods, a budget exists).
expected=$(k get pdb ledger-api-pdb -o jsonpath='{.status.expectedPods}')
minav=$(k get pdb ledger-api-pdb -o jsonpath='{.spec.minAvailable}')
maxun=$(k get pdb ledger-api-pdb -o jsonpath='{.spec.maxUnavailable}')
if [ "${expected:-0}" -lt 2 ] || { [ -z "$minav" ] && [ -z "$maxun" ]; }; then
  echo "❌ PDB ledger-api-pdb no longer protects the ledger-api pods"
  exit 1
fi
if [ "$maxun" = "100%" ] || [ "$minav" = "0" ] || [ "$minav" = "0%" ]; then
  echo "❌ PDB ledger-api-pdb allows every pod to go at once; it protects nothing"
  exit 1
fi
echo "✅ PDB ledger-api-pdb still protects ledger-api"
exit 0
exit 1
