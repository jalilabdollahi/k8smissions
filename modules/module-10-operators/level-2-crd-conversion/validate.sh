#!/bin/bash
. ../_fixtures/lib.sh
CRD=caches.cache.acme.io

strategy=$(kubectl get crd $CRD -o jsonpath='{.spec.conversion.strategy}' 2>/dev/null)
if [ "$strategy" != "Webhook" ]; then
  echo "❌ the Cache CRD does not convert between versions through a webhook (strategy: ${strategy:-none})"
  exit 1
fi
echo "✅ the Cache CRD converts through a webhook"

# existing v1alpha1 objects read as v1 with the converted memory
bad=0
for row in "sessions 512Mi" "catalog 1024Mi" "ratelimits 128Mi"; do
  set -- $row
  got=$(timeout 15 kubectl -n "$NS" get caches.v1.cache.acme.io "$1" -o jsonpath='{.spec.memory}' 2>&1)
  if [ "$got" != "$2" ]; then
    echo "❌ cache $1 read as v1 has memory '${got:0:120}', expected $2"
    bad=1
  fi
done
[ "$bad" = 0 ] || exit 1
echo "✅ existing caches read as v1 with their memory"

# a v1 object round-trips to v1alpha1 (the stored version)
kubectl -n "$NS" delete caches.v1.cache.acme.io probe-v1 --ignore-not-found >/dev/null 2>&1
if ! kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<'Y'
apiVersion: cache.acme.io/v1
kind: Cache
metadata: {name: probe-v1}
spec: {memory: 256Mi, evictionPolicy: allkeys-lru}
Y
then
  echo "❌ creating a v1 Cache failed"
  exit 1
fi
mb=$(timeout 15 kubectl -n "$NS" get caches.v1alpha1.cache.acme.io probe-v1 -o jsonpath='{.spec.maxMemoryMB}' 2>/dev/null)
if [ "$mb" != "256" ]; then
  kubectl -n "$NS" delete caches.v1.cache.acme.io probe-v1 --ignore-not-found >/dev/null 2>&1
  echo "❌ a v1 cache with 256Mi reads as v1alpha1 maxMemoryMB '${mb:-nothing}', expected 256"
  exit 1
fi
echo "✅ a cache created as v1 reads back as v1alpha1 with maxMemoryMB 256"

# the controller sizes from the converted value
ok=0
for i in $(seq 1 12); do
  a=$(kubectl -n "$NS" get cm cache-sessions -o jsonpath='{.data.maxmemory}' 2>/dev/null)
  b=$(kubectl -n "$NS" get cm cache-probe-v1 -o jsonpath='{.data.maxmemory}' 2>/dev/null)
  c=$(kubectl -n "$NS" get cm cache-catalog -o jsonpath='{.data.maxmemory}' 2>/dev/null)
  if [ "$a" = 512Mi ] && [ "$b" = 256Mi ] && [ "$c" = 1024Mi ]; then ok=1; break; fi
  sleep 2
done
kubectl -n "$NS" delete caches.v1.cache.acme.io probe-v1 --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete cm cache-probe-v1 --ignore-not-found >/dev/null 2>&1
if [ "$ok" != 1 ]; then
  echo "❌ cache-controller sized sessions at '${a:-?}' and the probe at '${b:-?}', not from their real memory"
  exit 1
fi
echo "✅ cache-controller sizes caches from their real memory"

# nothing was reverted underneath us
if [ "$(kubectl get crd $CRD -o jsonpath='{.spec.conversion.strategy}')" != "Webhook" ]; then
  echo "❌ the conversion strategy did not stick"
  exit 1
fi
exit 0
exit 1
