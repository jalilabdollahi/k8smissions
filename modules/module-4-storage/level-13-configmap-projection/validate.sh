#!/bin/bash
# Level 13: config-reader must see the URL from the ConfigMap and the password from the Secret.
. ../_fixtures/lib.sh

for o in configmap/db-config secret/db-secret; do
  if ! kubectl get "$o" -n "$NS" >/dev/null 2>&1; then
    bad "$o does not exist"
    exit 1
  fi
done
if ! kubectl get deployment config-reader -n "$NS" >/dev/null 2>&1; then
  bad "Deployment config-reader does not exist"
  exit 1
fi
POD=$(kubectl get pods -n "$NS" -l app=config-reader --field-selector=status.phase=Running \
  -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$POD" ] || \
   [ "$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.status.containerStatuses[0].ready}')" != "true" ]; then
  bad "config-reader has no Ready pod"
  exit 1
fi
ok "$POD is Ready"

WANT_URL=$(kubectl get configmap db-config -n "$NS" -o jsonpath='{.data.db\.url}')
WANT_PW=$(kubectl get secret db-secret -n "$NS" -o jsonpath='{.data.db\.password}' | base64 -d)
GOT_URL=$(kubectl exec -n "$NS" "$POD" -- cat /etc/db/db.url 2>/dev/null)
GOT_PW=$(kubectl exec -n "$NS" "$POD" -- cat /etc/db/db.password 2>/dev/null)
if [ -z "$WANT_PW" ] || [ -z "$WANT_URL" ]; then
  bad "the sources db-config (db.url) or db-secret (db.password) lost their values"
  exit 1
fi
if [ "$GOT_URL" != "$WANT_URL" ]; then
  bad "/etc/db/db.url does not hold the value from ConfigMap db-config"
  exit 1
fi
if [ "$GOT_PW" != "$WANT_PW" ]; then
  bad "/etc/db/db.password does not hold the value from Secret db-secret"
  exit 1
fi
ok "db.url comes from the ConfigMap, db.password from the Secret"

ensure_probe || { bad "could not start the test client pod"; exit 1; }
S=$(pcurl http://config-reader/ | tr -d '\r\n')
if [ "$S" != "config=ok" ]; then
  bad "config-reader reports '${S:-no answer}'"
  exit 1
fi
ok "config-reader reports config=ok"

sleep 15
R=$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.status.containerStatuses[0].restartCount}')
S=$(pcurl http://config-reader/ | tr -d '\r\n')
if [ "$R" != "0" ] || [ "$S" != "config=ok" ]; then
  bad "not stable after 15s (restarts: $R, status: ${S:-no answer})"
  exit 1
fi
ok "still config=ok after 15s without restarts"
exit 0
exit 1
