#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get deploy critical-api >/dev/null 2>&1; then
  echo "❌ Deployment critical-api does not exist"
  exit 1
fi
if ! k rollout status deploy/critical-api --timeout=40s >/dev/null 2>&1; then
  echo "❌ critical-api is not fully rolled out before the test"
  exit 1
fi

stype=$(k get deploy critical-api -o jsonpath='{.spec.strategy.type}')
if [ "$stype" = "Recreate" ]; then
  echo "❌ critical-api still stops every pod at once during a release"
  exit 1
fi
echo "✅ the strategy no longer stops every pod at once"

# Perform a release ourselves and watch the Service while it rolls out.
stamp=$(date +%s)
echo "releasing a new template and polling the Service during the rollout..."
k exec probe -- sh -c 'rm -f /tmp/res; for i in $(seq 70); do curl -s --max-time 1 -o /dev/null -w "%{http_code}\n" http://critical-api >> /tmp/res; sleep 0.5; done' >/dev/null 2>&1 &
poller=$!
sleep 2
k patch deploy critical-api --type=merge -p "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"release\":\"validate-$stamp\"}}}}}" >/dev/null
k rollout status deploy/critical-api --timeout=60s >/dev/null 2>&1
rs=$?
wait $poller
out=$(k exec probe -- cat /tmp/res 2>/dev/null)
total=$(echo "$out" | grep -c .)
bad=$(echo "$out" | grep -vc '^200$')

if [ "$rs" -ne 0 ]; then
  echo "❌ the rollout did not complete"
  exit 1
fi
new=$(k get deploy critical-api -o jsonpath='{.status.updatedReplicas}/{.status.availableReplicas}')
if [ "$new" != "4/4" ]; then
  echo "❌ critical-api: updated/available replicas are $new, expected 4/4"
  exit 1
fi
echo "✅ 4 of 4 pods run the new template"
if [ "$total" -lt 50 ]; then
  echo "❌ could not collect enough samples ($total)"
  exit 1
fi
if [ "$bad" -ne 0 ]; then
  echo "❌ critical-api: $bad of $total requests failed during the release"
  exit 1
fi
echo "✅ critical-api: $total of $total requests succeeded during the release"
exit 0
exit 1
