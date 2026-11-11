#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get deploy inventory >/dev/null 2>&1; then
  echo "❌ Deployment inventory does not exist"
  exit 1
fi

if ! k wait --for=condition=Ready pod -l app=inventory --timeout=40s >/dev/null 2>&1; then
  echo "❌ the inventory pods are not Ready"
  exit 1
fi
n=$(k get pods -l app=inventory --field-selector=status.phase=Running --no-headers | wc -l | tr -d ' ')
if [ "$n" -ne 2 ]; then
  echo "❌ inventory: $n of 2 pods running"
  exit 1
fi
echo "✅ both inventory pods are Ready"

if [ -z "$(k get deploy inventory -o jsonpath='{.spec.template.spec.containers[0].livenessProbe}')" ]; then
  echo "❌ inventory has no liveness probe any more; a hung app would never be restarted"
  exit 1
fi
echo "✅ the liveness probe is still in place"

restarts() { k get pods -l app=inventory -o jsonpath='{range .items[*]}{.metadata.name}={.status.containerStatuses[0].restartCount} {end}'; }
before=$(restarts)
sleep 30
after=$(restarts)
if [ "$before" != "$after" ]; then
  echo "❌ inventory is still restarting (before: $before / after: $after)"
  exit 1
fi
if ! k wait --for=condition=Ready pod -l app=inventory --timeout=5s >/dev/null 2>&1; then
  echo "❌ the inventory pods lost readiness during the watch window"
  exit 1
fi
echo "✅ no restarts during a 30 second window"

out=$(k exec probe -- sh -c 'for i in $(seq 10); do curl -s --max-time 2 -o /dev/null -w "%{http_code}\n" http://inventory; done' 2>/dev/null)
ok=$(echo "$out" | grep -c '^200$')
if [ "$ok" -ne 10 ]; then
  echo "❌ inventory: only $ok of 10 requests returned 200"
  exit 1
fi
echo "✅ inventory: 10 of 10 requests returned 200"
exit 0
exit 1
