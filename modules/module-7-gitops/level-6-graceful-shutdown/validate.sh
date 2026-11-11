#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

want=$(k get deploy catalog -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ "${want:-0}" -ne 4 ]; then
  echo "❌ Deployment catalog has ${want:-0} replicas, it must keep 4"
  exit 1
fi
k wait --for=condition=Available deploy/catalog --timeout=30s >/dev/null 2>&1 || { echo "❌ Deployment catalog is not available"; exit 1; }

k exec probe -- rm -f /tmp/stop /tmp/fail /tmp/total >/dev/null 2>&1
k exec probe -- sh -c '
  f=0; t=0
  while [ ! -f /tmp/stop ]; do
    c=$(curl -s -o /dev/null -w "%{http_code}" --max-time 1 http://catalog)
    t=$((t+1)); [ "$c" = 200 ] || f=$((f+1))
  done
  echo "$f $t" > /tmp/result' >/dev/null 2>&1 &
loop=$!
sleep 2
k rollout restart deploy/catalog >/dev/null
k rollout status deploy/catalog --timeout=80s >/dev/null 2>&1
rc=$?
sleep 3
k exec probe -- touch /tmp/stop >/dev/null 2>&1
wait $loop
read -r failed total <<<"$(k exec probe -- cat /tmp/result 2>/dev/null)"
if [ "$rc" -ne 0 ]; then
  echo "❌ the rollout did not finish within 80s"
  exit 1
fi
if [ -z "${total:-}" ] || [ "$total" -lt 50 ]; then
  echo "❌ the request loop did not run properly (${total:-0} requests)"
  exit 1
fi
if [ "$failed" -ne 0 ]; then
  echo "❌ during the rollout $failed of $total requests to catalog failed"
  exit 1
fi
echo "✅ rollout finished, $total of $total requests succeeded"

ready=$(k get deploy catalog -o jsonpath='{.status.readyReplicas}')
if [ "${ready:-0}" -ne 4 ]; then
  echo "❌ Deployment catalog: ${ready:-0} of 4 pods Ready"
  exit 1
fi
echo "✅ catalog has 4 Ready replicas"
exit 0
exit 1
