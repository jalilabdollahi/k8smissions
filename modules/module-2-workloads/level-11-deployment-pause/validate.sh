#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get deploy frontend >/dev/null 2>&1; then
  echo "❌ Deployment frontend does not exist"
  exit 1
fi
paused=$(k get deploy frontend -o jsonpath='{.spec.paused}')
if [ "$paused" = "true" ]; then
  echo "❌ frontend is still paused, so its spec changes are not being rolled out"
  exit 1
fi
echo "✅ frontend is not paused"

if ! k rollout status deploy/frontend --timeout=45s >/dev/null 2>&1; then
  echo "❌ the rollout of frontend has not completed"
  exit 1
fi
want=$(k get deploy frontend -o jsonpath='{.spec.replicas}')
upd=$(k get deploy frontend -o jsonpath='{.status.updatedReplicas}')
avail=$(k get deploy frontend -o jsonpath='{.status.availableReplicas}')
if [ "${want:-0}" -ne 3 ] || [ "${upd:-0}" -ne 3 ] || [ "${avail:-0}" -ne 3 ]; then
  echo "❌ frontend: ${upd:-0} updated and ${avail:-0} available of 3"
  exit 1
fi
echo "✅ frontend: 3 of 3 replicas updated and available"

out=$(k exec probe -- sh -c 'for i in $(seq 15); do curl -s --max-time 2 http://frontend; done' 2>/dev/null)
new=$(echo "$out" | grep -c 'version=2.4 cart=on')
if [ "$new" -ne 15 ]; then
  echo "❌ frontend: only $new of 15 responses came from the new build"
  exit 1
fi
echo "✅ frontend: 15 of 15 responses are version=2.4 cart=on"
exit 0
exit 1
