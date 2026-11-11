#!/bin/bash
# Level 7: db-client authenticates with the mounted Secret, steadily.
. ../_fixtures/lib.sh

if ! kubectl get deployment db-client -n "$NS" >/dev/null 2>&1; then
  bad "Deployment db-client does not exist"
  exit 1
fi
if ! kubectl get secret db-credentials -n "$NS" >/dev/null 2>&1; then
  bad "Secret db-credentials does not exist"
  exit 1
fi
LAST=$(kubectl get secret db-credentials -n "$NS" -o jsonpath='{.data.password}' | base64 -d | tail -c 1 | od -An -tx1 | tr -d ' ')
case "$LAST" in
  0a|0d|20|09) bad "the stored password ends with a whitespace byte (0x$LAST)"; exit 1 ;;
  "") bad "Secret db-credentials has no password"; exit 1 ;;
esac
ok "the stored password has no stray trailing byte"

POD=$(kubectl get pods -n "$NS" -l app=db-client -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if ! kubectl get pod "$POD" -n "$NS" -o jsonpath='{.spec.volumes[*].secret.secretName}' | grep -qw db-credentials; then
  bad "the db-client pod does not mount Secret db-credentials"
  exit 1
fi
if [ "$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.status.containerStatuses[0].ready}')" != "true" ]; then
  bad "db-client pod is not Ready"
  exit 1
fi

ensure_probe || { bad "could not start the test client pod"; exit 1; }
for i in 1 2 3 4 5; do
  S=$(pcurl http://db-client/ | tr -d '\r\n')
  if [ "$S" != "auth=ok" ]; then
    bad "db-client /status says '${S:-no answer}' (check $i of 5)"
    exit 1
  fi
  [ "$i" -lt 5 ] && sleep 5
done
ok "db-client reported auth=ok for 20 seconds"
exit 0
exit 1
