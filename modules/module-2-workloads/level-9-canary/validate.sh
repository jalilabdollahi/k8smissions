#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

for d in app-stable app-canary; do
  if ! k get deploy "$d" >/dev/null 2>&1; then
    echo "❌ Deployment $d does not exist"
    exit 1
  fi
done
if ! k get svc app >/dev/null 2>&1; then
  echo "❌ Service app does not exist"
  exit 1
fi

for d in app-stable app-canary; do
  want=$(k get deploy "$d" -o jsonpath='{.spec.replicas}')
  ready=$(k get deploy "$d" -o jsonpath='{.status.readyReplicas}')
  if [ "${want:-0}" -lt 1 ] || [ "${ready:-0}" -ne "$want" ]; then
    echo "❌ $d: ${ready:-0} of ${want:-0} pods Ready"
    exit 1
  fi
done
echo "✅ both Deployments exist and every pod is Ready"

st=$(k get deploy app-stable -o jsonpath='{.status.readyReplicas}')
ca=$(k get deploy app-canary -o jsonpath='{.status.readyReplicas}')
if [ $((ca * 100 / (st + ca))) -gt 15 ]; then
  echo "❌ the canary owns $ca of $((st + ca)) endpoints behind Service app, far above a 10% experiment"
  exit 1
fi

out=$(k exec probe -- sh -c 'for i in $(seq 200); do curl -s --max-time 2 http://app; echo; done' 2>/dev/null)
canary=$(echo "$out" | grep -c 'canary build')
stable=$(echo "$out" | grep -c 'stable build')
total=$((canary + stable))
if [ "$total" -lt 190 ]; then
  echo "❌ Service app only answered $total of 200 requests"
  exit 1
fi
pct=$((canary * 100 / total))
if [ "$canary" -lt 2 ]; then
  echo "❌ the canary received $canary of $total requests; the experiment needs real traffic"
  exit 1
fi
if [ "$pct" -gt 20 ]; then
  echo "❌ the canary received $canary of $total requests ($pct%), the target is about 10%"
  exit 1
fi
echo "✅ the canary received $canary of $total requests ($pct%)"
exit 0
exit 1
