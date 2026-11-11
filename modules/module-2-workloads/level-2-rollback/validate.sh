#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get deploy web-app >/dev/null 2>&1; then
  echo "❌ Deployment web-app does not exist"
  exit 1
fi

if ! k rollout status deploy/web-app --timeout=40s >/dev/null 2>&1; then
  echo "❌ the rollout of web-app has not completed"
  exit 1
fi
echo "✅ rollout of web-app is complete"

want=$(k get deploy web-app -o jsonpath='{.spec.replicas}')
avail=$(k get deploy web-app -o jsonpath='{.status.availableReplicas}')
if [ "$want" -ne 4 ] || [ "${avail:-0}" -ne 4 ]; then
  echo "❌ web-app: ${avail:-0} of 4 replicas available (spec says $want)"
  exit 1
fi
echo "✅ web-app has 4 of 4 replicas available"

waiting=$(k get pods -l app=web-app -o jsonpath='{range .items[*]}{.status.containerStatuses[*].state.waiting.reason}{"\n"}{end}' | grep -c .)
if [ "$waiting" -ne 0 ]; then
  echo "❌ $waiting pod(s) of web-app are still waiting on a container"
  exit 1
fi

revs=$(k get rs -l app=web-app --no-headers 2>/dev/null | wc -l | tr -d ' ')
if [ "$revs" -lt 3 ]; then
  echo "❌ the revision history was thrown away (only $revs ReplicaSet(s) left)"
  exit 1
fi
echo "✅ revision history is intact"

out=$(k exec probe -- sh -c 'for i in $(seq 20); do curl -s --max-time 2 -o /dev/null -w "%{http_code}\n" http://web-app; done' 2>/dev/null)
ok=$(echo "$out" | grep -c '^200$')
if [ "$ok" -ne 20 ]; then
  echo "❌ web-app: only $ok of 20 requests returned 200"
  exit 1
fi
echo "✅ web-app: 20 of 20 requests returned 200"
exit 0
exit 1
