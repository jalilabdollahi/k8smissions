#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }
W=workloads.platform.acme.io

est=$(kubectl get crd $W -o jsonpath='{.status.conditions[?(@.type=="Established")].status}' 2>/dev/null)
if [ "$est" != "True" ]; then
  echo "❌ the Workload CRD ($W) is not installed and Established"
  exit 1
fi
echo "✅ the Workload CRD is Established"

pod_state() { k get pods -l app=workload-operator -o jsonpath='{range .items[*]}{.status.phase}/{.status.containerStatuses[0].restartCount}/{.status.containerStatuses[0].ready}{" "}{end}' 2>/dev/null; }
s1=$(pod_state)
if [ "$(echo "$s1" | wc -w | tr -d ' ')" != 1 ] || ! echo "$s1" | grep -q '^Running/[0-9]*/true $'; then
  echo "❌ workload-operator is not a single Running, Ready pod (seen: ${s1:-no pod})"
  exit 1
fi
sleep 8
s2=$(pod_state)
if [ "$s1" != "$s2" ]; then
  echo "❌ workload-operator is not stable: $s1 became $s2"
  exit 1
fi
echo "✅ workload-operator is Running and not restarting"

for w in api worker legacy-sync; do
  ph=$(k get $W $w -o jsonpath='{.status.phase}' 2>/dev/null)
  if [ -z "$ph" ]; then
    echo "❌ Workload $w has no status.phase (missing or not reconciled)"
    exit 1
  fi
done
echo "✅ api, worker and legacy-sync all have a status.phase"

k delete $W probe-no-options --ignore-not-found >/dev/null 2>&1
k apply -f - >/dev/null 2>&1 <<'Y'
apiVersion: platform.acme.io/v1
kind: Workload
metadata: {name: probe-no-options}
spec: {image: registry.acme.io/probe:0.1.0}
Y
ok=0
for i in $(seq 1 10); do
  [ -n "$(k get $W probe-no-options -o jsonpath='{.status.phase}' 2>/dev/null)" ] && { ok=1; break; }
  sleep 1
done
sleep 3
s3=$(pod_state)
k delete $W probe-no-options --ignore-not-found >/dev/null 2>&1
if [ "$ok" != 1 ] || [ "$s3" != "$s1" ]; then
  echo "❌ a Workload without spec.options is not handled: reconciled=$ok, operator state $s1 -> $s3"
  exit 1
fi
echo "✅ a Workload without spec.options is reconciled and the operator keeps running"
exit 0
exit 1
