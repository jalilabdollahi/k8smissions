#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

# nothing may be deleted to make the problem go away
for p in payments-db payments-api batch-exporter debug-shell; do
  phase=$(k get pod "$p" -o jsonpath='{.status.phase}' 2>/dev/null)
  if [ "$phase" != "Running" ]; then
    echo "❌ pod $p must stay Running (found: ${phase:-missing})"
    exit 1
  fi
done
if ! k get svc payments-db >/dev/null 2>&1; then
  echo "❌ Service payments-db is missing"
  exit 1
fi
echo "✅ all four workloads are Running"

fetch() { # pod
  k exec "$1" -- curl -s --max-time 3 http://payments-db:8080 2>/dev/null
}

out=$(fetch payments-api)
if [ "$out" != "payments-db: ledger ready" ]; then
  echo "❌ payments-api cannot reach payments-db:8080 by service name (got: ${out:-no answer})"
  exit 1
fi
echo "✅ payments-api reaches payments-db:8080 through its service name"

# policy changes take a few seconds to be programmed, so allow a short window
for i in 1 2 3 4 5 6; do
  leak=""
  for p in batch-exporter debug-shell; do
    if [ -n "$(fetch $p)" ]; then leak="$leak $p"; fi
  done
  [ -z "$leak" ] && break
  sleep 3
done
if [ -n "$leak" ]; then
  echo "❌ still able to reach payments-db:8080 from:$leak"
  exit 1
fi
echo "✅ batch-exporter and debug-shell are blocked"

out=$(fetch payments-api)
if [ "$out" != "payments-db: ledger ready" ]; then
  echo "❌ payments-api lost access while tightening"
  exit 1
fi
exit 0
exit 1
