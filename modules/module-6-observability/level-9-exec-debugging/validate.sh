#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

img=$(k get deploy quote-api -o jsonpath='{.spec.template.spec.containers[*].image}' 2>/dev/null)
case "$img" in
  hashicorp/http-echo:*) ;;
  *) echo "❌ Deployment quote-api must keep running the hashicorp/http-echo image (found: ${img:-no deployment})"; exit 1 ;;
esac
pods=$(../_fixtures/live-pods.sh app=quote-api)
ready=0
for p in $pods; do
  [ "$(k get pod "$p" -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)" = "true" ] && ready=$((ready + 1))
done
if [ "$ready" -lt 1 ]; then
  echo "❌ no Ready quote-api pod"
  exit 1
fi
echo "✅ quote-api has $ready Ready pod(s) on the original image"

../_fixtures/ensure-probe.sh
tp=$(k get svc quote-api -o jsonpath='{.spec.ports[0].targetPort}' 2>/dev/null)
bad=0
for p in $pods; do
  ip=$(k get pod "$p" -o jsonpath='{.status.podIP}')
  if ! k exec probe -- curl -s --max-time 4 -o /dev/null "http://$ip:${tp:-5678}/" 2>/dev/null; then
    echo "❌ pod $p ($ip) refuses connections on port ${tp:-5678} from another pod"
    bad=1
  fi
done
[ "$bad" -eq 0 ] || exit 1
echo "✅ the pod IP accepts connections from outside the pod"

want=0
for i in 1 2 3 4; do
  out=$(k exec probe -- curl -s --max-time 4 http://quote-api/ 2>/dev/null)
  case "$out" in "Quote of the day"*) want=$((want + 1)) ;; esac
done
if [ "$want" -ne 4 ]; then
  echo "❌ only $want of 4 requests through Service quote-api returned the quote"
  exit 1
fi
echo "✅ Service quote-api returns the quote"
exit 0
exit 1
