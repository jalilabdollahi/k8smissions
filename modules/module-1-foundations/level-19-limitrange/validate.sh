#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

ratio=$(k get limitrange team-defaults -o jsonpath='{.spec.limits[?(@.type=="Container")].maxLimitRequestRatio.memory}' 2>/dev/null)
if [ -z "$ratio" ] || [ "$ratio" -gt 2 ] 2>/dev/null; then
  echo "❌ LimitRange team-defaults no longer enforces its memory ratio"
  exit 1
fi
echo "✅ LimitRange team-defaults is still enforced"

ready=$(k get deploy invoice-render -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -ne 3 ]; then
  echo "❌ Deployment invoice-render: ${ready:-0} of 3 pods Ready"
  exit 1
fi
echo "✅ invoice-render has 3 Ready pods"

out=$(k exec probe -- sh -c 'for i in 1 2 3 4 5 6; do curl -s --max-time 8 http://invoice-render/render; done' 2>/dev/null)
n=$(echo "$out" | grep -c 'invoice rendered')
if [ "$n" -ne 6 ]; then
  echo "❌ only $n of 6 render requests succeeded"
  exit 1
fi
sleep 3
restarts=$(k get pods -l app=invoice-render -o jsonpath='{range .items[*]}{.status.containerStatuses[0].restartCount}{"\n"}{end}' | grep -vc '^0$')
if [ "$restarts" != "0" ]; then
  echo "❌ invoice-render pods restarted during the renders"
  exit 1
fi
echo "✅ 6 of 6 renders succeeded without restarts"
exit 0
exit 1
