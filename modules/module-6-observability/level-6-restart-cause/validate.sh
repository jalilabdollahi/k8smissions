#!/bin/bash
C=cart
k() { kubectl -n "$C" "$@"; }

if [ "$(k get limitrange cart-limits -o jsonpath='{.spec.limits[0].max.memory}' 2>/dev/null)" != "128Mi" ]; then
  echo "❌ LimitRange cart-limits must stay in place with its 128Mi ceiling"
  exit 1
fi
echo "✅ the LimitRange is unchanged"

need=0
for d in cart-cache cart-worker cart-reporter; do
  a=$(../_fixtures/min-age.sh -n "$C" "app=$d")
  [ "${a:-0}" -lt 40 ] && [ $(( 40 - ${a:-0} )) -gt "$need" ] && need=$(( 40 - ${a:-0} ))
done
if [ "$need" -gt 0 ] && [ "$need" -le 40 ]; then
  echo "… watching the pods for another ${need}s"
  sleep "$need"
fi

for d in cart-cache cart-worker cart-reporter; do
  st=""
  for p in $(../_fixtures/live-pods.sh -n "$C" "app=$d"); do
    st="$st$(k get pod "$p" -o jsonpath='{.status.containerStatuses[0].ready}/{.status.containerStatuses[0].restartCount}')"$'\n'
  done
  st=$(echo "$st" | sed '/^$/d')
  if [ "$st" != "true/0" ]; then
    echo "❌ $d: not stable yet (ready/restarts: ${st:-no pod})"
    exit 1
  fi
done
echo "✅ all three pods are Ready and have not restarted"

if [ "$(k get deploy cart-reporter -o jsonpath='{.spec.template.spec.containers[0].livenessProbe}' 2>/dev/null)" = "" ]; then
  echo "❌ cart-reporter lost its liveness probe"
  exit 1
fi
echo "✅ cart-reporter still has a liveness probe"

mb=$(k logs deploy/cart-cache --tail=5 2>/dev/null | sed -n 's/^cart-cache: cache warmed \([0-9]*\) MB$/\1/p' | tail -1)
if [ "${mb:-0}" -lt 16 ] || [ "${mb:-0}" -ge 128 ]; then
  echo "❌ cart-cache should hold a real cache that fits under the ceiling (warmed: ${mb:-nothing} MB)"
  exit 1
fi
echo "✅ cart-cache holds ${mb} MB and stays up"

if ! k logs deploy/cart-worker --tail=5 2>/dev/null | grep -q '^cart-worker: processed job-[0-9]*$'; then
  echo "❌ cart-worker is not processing jobs from the queue"
  exit 1
fi
echo "✅ cart-worker is processing jobs"
exit 0
exit 1
