#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get deploy api-server >/dev/null 2>&1; then
  echo "❌ Deployment api-server does not exist"
  exit 1
fi
want=$(k get deploy api-server -o jsonpath='{.spec.replicas}')
upd=$(k get deploy api-server -o jsonpath='{.status.updatedReplicas}')
avail=$(k get deploy api-server -o jsonpath='{.status.availableReplicas}')
image=$(k get deploy api-server -o jsonpath='{.spec.template.spec.containers[0].image}')
hp=$(k get deploy api-server -o jsonpath='{.spec.template.spec.containers[0].ports[0].hostPort}')
if [ "$want" != "2" ]; then
  echo "❌ api-server runs $want replica(s); it must keep 2, one per node"
  exit 1
fi
if [ "$hp" != "9000" ]; then
  echo "❌ the pods no longer bind hostPort 9000; the node-local agent depends on it"
  exit 1
fi
if [ "$image" != "nginx:1.27-alpine" ]; then
  echo "❌ api-server runs image $image instead of the new release"
  exit 1
fi
if [ "${upd:-0}" -ne 2 ] || [ "${avail:-0}" -ne 2 ]; then
  echo "❌ api-server: ${upd:-0} updated and ${avail:-0} available of 2"
  exit 1
fi
if ! k rollout status deploy/api-server --timeout=40s >/dev/null 2>&1; then
  echo "❌ the rollout of api-server has not completed"
  exit 1
fi
echo "✅ api-server: rollout complete, 2 of 2 updated and available on nginx:1.27-alpine"

# Prove the next release also goes through, without dropping requests.
k exec probe -- sh -c 'rm -f /tmp/res; for i in $(seq 100); do curl -s --max-time 1 -o /dev/null -w "%{http_code}\n" http://api-server >> /tmp/res; sleep 0.4; done' >/dev/null 2>&1 &
poller=$!
k patch deploy api-server --type=merge -p "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"k8smissions/release\":\"$(date +%s)\"}}}}}" >/dev/null
ok=0
k rollout status deploy/api-server --timeout=50s >/dev/null 2>&1 && ok=1
kill $poller 2>/dev/null; wait $poller 2>/dev/null
out=$(k exec probe -- cat /tmp/res 2>/dev/null)
total=$(echo "$out" | grep -c .)
bad=$(echo "$out" | grep -vc '^200$')

if [ "$ok" -ne 1 ]; then
  echo "❌ a second rollout of api-server did not complete in time"
  exit 1
fi
echo "✅ a further rollout completes"
if [ "$total" -lt 10 ]; then
  echo "❌ could not collect enough samples from the Service ($total)"
  exit 1
fi
if [ "$bad" -ne 0 ]; then
  echo "❌ api-server: $bad of $total requests failed during the rollout"
  exit 1
fi
echo "✅ api-server: $total of $total requests succeeded during the rollout"
exit 0
exit 1
