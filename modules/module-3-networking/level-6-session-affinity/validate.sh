#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

r=$(k get deploy portal -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${r:-0}" -ne 3 ]; then
  echo "❌ Deployment portal: ${r:-0} of 3 pods Ready"
  exit 1
fi
echo "✅ portal has 3 Ready pods"

for c in probe probe-b; do
  out=$(k exec "$c" -- sh -c '
    jar=$(mktemp)
    curl -s --max-time 3 -c $jar "http://portal/login?user=mara" >/dev/null
    for i in $(seq 20); do curl -s --max-time 3 -b $jar http://portal/; done' 2>/dev/null)
  good=$(echo "$out" | grep -c '^user=mara$')
  if [ "$good" -ne 20 ]; then
    echo "❌ $c: the session survived only $good of 20 requests"
    exit 1
  fi
  echo "✅ $c: logged in once, 20 of 20 requests kept the session"
done
exit 0
exit 1
