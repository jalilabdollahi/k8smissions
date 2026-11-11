#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }
W=widgets.widgets.acme.io

ready=$(k get deploy widget-operator -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -lt 1 ]; then
  echo "❌ widget-operator has no Ready pod"
  exit 1
fi
if ! k logs deploy/widget-operator 2>/dev/null | grep -q 'widget-operator 1.4.0 starting'; then
  echo "❌ the running operator is not release 1.4.0"
  exit 1
fi
echo "✅ widget-operator is running release 1.4.0"

bad=0
for row in "gauge 2" "dial 1" "meter 3"; do
  set -- $row
  got=$(k get $W "$1" -o jsonpath='{.spec.sizing.replicas}/{.status.schemaVersion}/{.status.operatorVersion}/{.status.phase}' 2>/dev/null)
  cm=$(k get cm "widget-$1" -o jsonpath='{.data.replicas}' 2>/dev/null)
  if [ "$got" != "$2/2/1.4.0/Ready" ] || [ "$cm" != "$2" ]; then
    echo "❌ widget $1 is not migrated and reconciled by 1.4.0 (found '$got', replicas ConfigMap '${cm:-none}')"
    bad=1
  fi
done
[ "$bad" = 0 ] || exit 1
echo "✅ gauge, dial and meter are on schema 2 and reconciled by 1.4.0"

k delete $W probe-w --ignore-not-found >/dev/null 2>&1
k delete cm widget-probe-w --ignore-not-found >/dev/null 2>&1
k apply -f - >/dev/null <<'Y'
apiVersion: widgets.acme.io/v1
kind: Widget
metadata: {name: probe-w}
spec: {sizing: {replicas: 4}}
Y
ok=0
for i in $(seq 1 10); do
  cm=$(k get cm widget-probe-w -o jsonpath='{.data.replicas}' 2>/dev/null)
  ver=$(k get $W probe-w -o jsonpath='{.status.operatorVersion}' 2>/dev/null)
  if [ "$cm" = 4 ] && [ "$ver" = 1.4.0 ]; then ok=1; break; fi
  sleep 2
done
k delete $W probe-w --ignore-not-found >/dev/null 2>&1
k delete cm widget-probe-w --ignore-not-found >/dev/null 2>&1
if [ "$ok" != 1 ]; then
  echo "❌ a new Widget with spec.sizing.replicas is not reconciled by 1.4.0 (ConfigMap '${cm:-none}', operatorVersion '${ver:-none}')"
  exit 1
fi
echo "✅ a new Widget is reconciled by 1.4.0"
exit 0
exit 1
