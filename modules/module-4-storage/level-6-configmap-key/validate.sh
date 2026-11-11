#!/bin/bash
# Level 6: web-app starts, stays up, and serves the mounted settings file.
. ../_fixtures/lib.sh

if ! kubectl get configmap app-config -n "$NS" >/dev/null 2>&1; then
  bad "ConfigMap app-config does not exist"
  exit 1
fi
if ! kubectl get deployment web-app -n "$NS" >/dev/null 2>&1; then
  bad "Deployment web-app does not exist"
  exit 1
fi
POD=$(kubectl get pods -n "$NS" -l app=web-app -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
PHASE=$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$PHASE" != "Running" ] || \
   [ "$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.status.containerStatuses[0].ready}')" != "true" ]; then
  bad "web-app pod is not Ready (phase: ${PHASE:-none})"
  exit 1
fi
ok "$POD is Ready"

ensure_probe || { bad "could not start the test client pod"; exit 1; }
BODY=$(pcurl http://web-app/)
if ! echo "$BODY" | grep -q 'payments_url:'; then
  bad "Service web-app does not serve the settings file (got: $(echo "$BODY" | head -c 80))"
  exit 1
fi
ok "web-app serves the settings from /etc/app/app.yaml"

sleep 15
R=$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.status.containerStatuses[0].restartCount}')
READY=$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.status.containerStatuses[0].ready}')
if [ "$R" != "0" ] || [ "$READY" != "true" ]; then
  bad "web-app is not stable (restarts: $R, ready: $READY)"
  exit 1
fi
ok "still Ready with no restarts after 15s"
exit 0
exit 1
