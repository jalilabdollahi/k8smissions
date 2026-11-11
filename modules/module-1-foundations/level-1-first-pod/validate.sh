#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get pod welcome-page >/dev/null 2>&1; then
  echo "❌ Pod welcome-page does not exist"
  exit 1
fi
if [ "$(k get pod welcome-page -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)" != "true" ]; then
  echo "❌ Pod welcome-page is not Ready ($(k get pod welcome-page --no-headers 2>/dev/null | awk '{print $3}'))"
  exit 1
fi
echo "✅ Pod welcome-page is Ready"

sleep 15
restarts=$(k get pod welcome-page -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>/dev/null)
if [ "${restarts:-1}" -ne 0 ] || [ "$(k get pod welcome-page -o jsonpath='{.status.phase}')" != "Running" ]; then
  echo "❌ Pod welcome-page keeps restarting (restarts: ${restarts:-?})"
  exit 1
fi
echo "✅ Pod welcome-page ran 15s without a restart"

body=$(k exec probe -- curl -s --max-time 5 -w '\nHTTP %{http_code}' http://welcome-page 2>/dev/null)
if ! echo "$body" | grep -q 'HTTP 200' || ! echo "$body" | grep -q 'Welcome to nginx'; then
  echo "❌ Service welcome-page did not return the nginx welcome page"
  exit 1
fi
echo "✅ Service welcome-page returns 200 with the welcome page"
exit 0
exit 1
