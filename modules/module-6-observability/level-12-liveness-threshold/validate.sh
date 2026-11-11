#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }
P='{.spec.template.spec.containers[0].livenessProbe'

if ! k get deploy report-engine >/dev/null 2>&1; then
  echo "❌ Deployment report-engine does not exist"
  exit 1
fi
if [ -z "$(k get deploy report-engine -o jsonpath="$P}")" ]; then
  echo "❌ report-engine has no liveness probe any more; a hung pod would never be restarted"
  exit 1
fi
period=$(k get deploy report-engine -o jsonpath="$P.periodSeconds}")
timeout=$(k get deploy report-engine -o jsonpath="$P.timeoutSeconds}")
thr=$(k get deploy report-engine -o jsonpath="$P.failureThreshold}")
period=${period:-10}; timeout=${timeout:-1}; thr=${thr:-3}
window=$((period * thr))
if [ "$window" -gt 120 ]; then
  echo "❌ a hung pod would take ${window}s to be restarted (period ${period}s x threshold ${thr}); the limit is 120s"
  exit 1
fi
echo "✅ the liveness probe is still there and restarts a hung pod within ${window}s"

age=$(../_fixtures/min-age.sh app=report-engine)
if [ "${age:-0}" -lt 64 ]; then
  wait=$((64 - ${age:-0}))
  echo "… pod is ${age:-0}s old, watching it for another ${wait}s"
  sleep "$wait"
fi
pods=$(../_fixtures/live-pods.sh app=report-engine)
if [ "$(echo "$pods" | grep -c .)" -ne 1 ]; then
  echo "❌ expected exactly one live report-engine pod"
  exit 1
fi
st=$(k get pod "$pods" -o jsonpath='{.status.containerStatuses[0].ready}/{.status.containerStatuses[0].restartCount}')
if [ "$st" != "true/0" ]; then
  echo "❌ report-engine pod ready/restarts is $st (needs true/0 through two pause cycles)"
  exit 1
fi
echo "✅ the pod stayed Ready with no restarts through two compaction pauses"

../_fixtures/ensure-probe.sh
out=$(k exec probe -- curl -s --max-time 20 http://report-engine/ 2>/dev/null)
if [ "$out" != "report-engine: queue drained" ]; then
  echo "❌ Service report-engine did not answer (got: ${out:-nothing})"
  exit 1
fi
echo "✅ Service report-engine answers"
exit 0
exit 1
