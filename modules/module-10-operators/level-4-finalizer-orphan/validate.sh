#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }
fail=0

ready=$(k get deploy datastore-operator -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -lt 1 ]; then
  echo "❌ datastore-operator has no Ready pod"
  exit 1
fi

# the live datastore keeps everything
if k get datastore orders >/dev/null 2>&1 && k get pod ds-orders >/dev/null 2>&1 && k get cm ds-orders >/dev/null 2>&1; then
  echo "✅ orders still has its Datastore, Pod and ConfigMap"
else
  echo "❌ orders lost its Datastore, Pod or ConfigMap (or the operator has not built them yet)"
  fail=1
fi

# the leftovers of legacy-orders are gone
left=""
k get pod ds-legacy-orders >/dev/null 2>&1 && left="pod"
k get cm ds-legacy-orders >/dev/null 2>&1 && left="$left configmap"
if [ -n "$left" ]; then
  echo "❌ leftovers of legacy-orders are still there:$left"
  fail=1
else
  echo "✅ nothing is left of legacy-orders"
fi

# behaviour: create and delete a Datastore, and watch what happens to its backend
k delete datastore probe-store --ignore-not-found >/dev/null 2>&1
k apply -f - >/dev/null <<'Y'
apiVersion: data.acme.io/v1
kind: Datastore
metadata: {name: probe-store}
spec: {engine: mysql, sizeGB: 1}
Y
built=0
for i in $(seq 1 10); do
  if k get pod ds-probe-store >/dev/null 2>&1 && k get cm ds-probe-store >/dev/null 2>&1; then built=1; break; fi
  sleep 2
done
if [ "$built" != 1 ]; then
  echo "❌ the operator did not build a backend for a new Datastore"
  k delete datastore probe-store --ignore-not-found --wait=false >/dev/null 2>&1
  exit 1
fi
sleep 3  # let the operator register its finalizer
k delete datastore probe-store --wait=false >/dev/null 2>&1
for i in $(seq 1 10); do
  k get datastore probe-store >/dev/null 2>&1 || break
  sleep 2
done
if k get datastore probe-store >/dev/null 2>&1; then
  echo "❌ a deleted Datastore never went away (finalizer stuck)"
  k patch datastore probe-store --type=merge -p '{"metadata":{"finalizers":null}}' >/dev/null 2>&1
  k delete pod/ds-probe-store cm/ds-probe-store --ignore-not-found --wait=false >/dev/null 2>&1
  exit 1
fi
gone=0
for i in $(seq 1 15); do
  if ! k get pod ds-probe-store >/dev/null 2>&1 && ! k get cm ds-probe-store >/dev/null 2>&1; then gone=1; break; fi
  sleep 2
done
if [ "$gone" != 1 ]; then
  echo "❌ a deleted Datastore left its backing Pod or ConfigMap behind"
  k delete pod/ds-probe-store cm/ds-probe-store --ignore-not-found --wait=false >/dev/null 2>&1
  fail=1
else
  echo "✅ deleting a Datastore removes its Pod and ConfigMap"
fi
[ "$fail" = 0 ] && exit 0
exit 1
