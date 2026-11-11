#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

load=$(k get deploy search-load -o jsonpath='{.spec.replicas}/{.status.readyReplicas}/{.spec.template.spec.containers[0].image}' 2>/dev/null)
if [ "$load" != "2/2/busybox:1.36" ]; then
  echo "❌ the search-load generator must keep running at full rate (found: ${load:-gone})"
  exit 1
fi
echo "✅ search-load is still running at full rate"

for kind in livenessProbe readinessProbe; do
  t=$(k get deploy search-api -o jsonpath="{.spec.template.spec.containers[0].$kind.timeoutSeconds}" 2>/dev/null)
  h=$(k get deploy search-api -o jsonpath="{.spec.template.spec.containers[0].$kind.httpGet.path}" 2>/dev/null)
  if [ -z "$h" ] || [ "${t:-1}" -gt 30 ]; then
    echo "❌ search-api $kind must exist with a timeout of at most 30s (path: ${h:-none}, timeout: ${t:-default})"
    exit 1
  fi
done
echo "✅ both probes are still in place"

age=$(../_fixtures/min-age.sh app=search-api)
if [ "${age:-0}" -lt 50 ]; then
  wait=$(( 50 - ${age:-0} ))
  echo "… pods are ${age:-0}s old, watching them under load for another ${wait}s"
  sleep "$wait"
fi
st=""
for p in $(../_fixtures/live-pods.sh app=search-api); do
  st="$st$(k get pod "$p" -o jsonpath='{.status.containerStatuses[0].ready}/{.status.containerStatuses[0].restartCount}')"$'\n'
done
st=$(echo "$st" | sed '/^$/d')
if [ "$(echo "$st" | grep -c '^true/0$')" -ne 2 ] || [ "$(echo "$st" | grep -c .)" -ne 2 ]; then
  echo "❌ search-api needs 2 Ready pods without restarts (ready/restarts: $(echo $st))"
  exit 1
fi
echo "✅ both search-api pods stayed Ready under load"

../_fixtures/ensure-probe.sh
ok=0
for i in 1 2 3; do
  out=$(k exec probe -- curl -s --max-time 20 "http://search-api/search?q=shoes" 2>/dev/null)
  [ "$out" = "results: 3 hits for your query" ] && ok=$((ok + 1))
done
if [ "$ok" -ne 3 ]; then
  echo "❌ only $ok of 3 searches through the Service returned results"
  exit 1
fi
echo "✅ searches through the Service return results"
exit 0
exit 1
