#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

pods=$(../_fixtures/live-pods.sh app=quote-service)
if [ "$(echo "$pods" | grep -c .)" -ne 1 ]; then
  echo "❌ expected exactly one live quote-service pod, found: $(echo "$pods" | grep -c .)"
  exit 1
fi
pod=$pods
names=$(k get pod "$pod" -o jsonpath='{range .spec.containers[*]}{.name}{" "}{end}')
if [ "$names" != "metrics-proxy app " ] && [ "$names" != "app metrics-proxy " ]; then
  echo "❌ the pod must still run both the app and the metrics-proxy containers (found: $names)"
  exit 1
fi

age=$(../_fixtures/min-age.sh app=quote-service)
if [ "${age:-0}" -lt 40 ]; then
  wait=$(( 40 - ${age:-0} ))
  echo "… pod is ${age:-0}s old, watching it for another ${wait}s"
  sleep "$wait"
fi
status=$(k get pod "$pod" -o jsonpath='{range .status.containerStatuses[*]}{.name}={.ready}/{.restartCount}{"\n"}{end}' 2>/dev/null)
if echo "$status" | grep -qv '=true/0$' || [ "$(echo "$status" | grep -c .)" -ne 2 ]; then
  echo "❌ containers are not both ready without restarts:"
  echo "$status"
  exit 1
fi
echo "✅ both containers are Running and have not restarted"

../_fixtures/ensure-probe.sh
body=$(k exec probe -- curl -s --max-time 3 http://quote-service/ 2>/dev/null)
if [ "$body" != "quote: ship it on a Friday" ]; then
  echo "❌ Service quote-service did not return the quote (got: ${body:-nothing})"
  exit 1
fi
echo "✅ Service quote-service returns the quote"

ip=$(k get pod "$pod" -o jsonpath='{.status.podIP}')
ports=$(k exec "$pod" -c metrics-proxy -- sh -c "awk 'NR>1 && \$4==\"0A\" {split(\$2,a,\":\"); print a[2]}' /proc/net/tcp /proc/net/tcp6" 2>/dev/null | sort -u)
seen_quote=0; seen_metrics=0
for hex in $ports; do
  port=$((16#$hex))
  out=$(k exec probe -- curl -s --max-time 2 "http://$ip:$port/" 2>/dev/null)
  case "$out" in
    *proxy_up*) seen_metrics=1 ;;
    quote:*) seen_quote=1 ;;
  esac
done
if [ "$seen_quote" -ne 1 ] || [ "$seen_metrics" -ne 1 ]; then
  echo "❌ the app and the metrics-proxy must each answer on a port of their own"
  exit 1
fi
echo "✅ the app and the metrics-proxy each answer on their own port"
exit 0
exit 1
