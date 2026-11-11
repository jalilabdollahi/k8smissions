#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

b=$(k get deploy ledger-batch -o jsonpath='{.metadata.generation}/{.spec.replicas}/{.status.readyReplicas}/{.spec.template.spec.containers[0].env[?(@.name=="LOG_LEVEL")].value}' 2>/dev/null)
if [ "$b" != "1/1/1/INFO" ]; then
  echo "❌ ledger-batch must stay as it was, one Ready replica logging at INFO (found: ${b:-gone})"
  exit 1
fi
echo "✅ ledger-batch is untouched"

if ! k wait --for=condition=Available deploy/ledger-api --timeout=40s >/dev/null 2>&1; then
  echo "❌ ledger-api is not available"
  exit 1
fi
api=$(k get deploy ledger-api -o jsonpath='{.spec.replicas}/{.status.readyReplicas}/{.status.replicas}' 2>/dev/null)
if [ "$api" != "2/2/2" ]; then
  echo "❌ ledger-api needs 2 Ready replicas and no stragglers (found $api)"
  exit 1
fi

age=$(../_fixtures/min-age.sh app=ledger-api)
if [ "${age:-0}" -lt 34 ]; then
  wait=$((34 - ${age:-0}))
  echo "… ledger-api pods are ${age:-0}s old, measuring their output for another ${wait}s"
  sleep "$wait"
fi

for p in $(../_fixtures/live-pods.sh app=ledger-api); do
  recent=$(k logs "$p" --since=30s 2>/dev/null | grep -c .)
  if [ "$recent" -gt 10 ]; then
    echo "❌ $p wrote $recent lines in the last 30s (about $((recent * 2)) per minute, the limit is 20)"
    exit 1
  fi
  all=$(k logs "$p" 2>/dev/null)
  for lvl in WARN ERROR; do
    if ! echo "$all" | grep -q " $lvl  *ledger\| $lvl  *[a-z]"; then
      echo "❌ $p no longer writes $lvl lines"
      exit 1
    fi
  done
done
echo "✅ ledger-api is quiet, and still writes its WARN and ERROR lines"
exit 0
exit 1
