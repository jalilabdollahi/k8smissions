#!/bin/bash
# Level 8: writer-app signs as a non-root user and stays up.
. ../_fixtures/lib.sh

if ! kubectl get deployment writer-app -n "$NS" >/dev/null 2>&1; then
  bad "Deployment writer-app does not exist"
  exit 1
fi
if ! kubectl get secret signing-keys -n "$NS" >/dev/null 2>&1; then
  bad "Secret signing-keys does not exist"
  exit 1
fi
POD=$(kubectl get pods -n "$NS" -l app=writer-app --field-selector=status.phase=Running \
  -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$POD" ] || \
   [ "$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.status.containerStatuses[0].ready}')" != "true" ]; then
  bad "writer-app has no Ready pod (it is crashing or not started)"
  exit 1
fi
ok "$POD is Ready"

UID_IN=$(kubectl exec -n "$NS" "$POD" -- id -u 2>/dev/null | tr -d '\r\n')
if [ -z "$UID_IN" ] || [ "$UID_IN" = "0" ]; then
  bad "the app runs as uid ${UID_IN:-unknown}; it must not run as root"
  exit 1
fi
ok "the app runs as uid $UID_IN (not root)"

ensure_probe || { bad "could not start the test client pod"; exit 1; }
S=$(pcurl http://writer-app/ | tr -d '\r\n')
case "$S" in
  "signed=ok uid=$UID_IN") ok "status: $S" ;;
  *) bad "writer-app status is '${S:-no answer}'"; exit 1 ;;
esac

sleep 25
R=$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.status.containerStatuses[0].restartCount}')
S=$(pcurl http://writer-app/ | tr -d '\r\n')
if [ "$R" != "0" ] || [ "$S" != "signed=ok uid=$UID_IN" ]; then
  bad "not stable after 25s (restarts: $R, status: ${S:-no answer})"
  exit 1
fi
ok "no restarts and still signing after 25s"
exit 0
exit 1
