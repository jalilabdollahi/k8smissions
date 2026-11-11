#!/bin/bash
NS=${NS:-k8smissions}

pw=$(kubectl -n "$NS" get secret inventory-cache-credentials -o jsonpath='{.data.CACHE_PASSWORD}' 2>/dev/null | base64 -d 2>/dev/null)
if [ -z "$pw" ]; then
  echo "❌ Secret inventory-cache-credentials (or its CACHE_PASSWORD key) is gone"
  exit 1
fi
cpw=$(kubectl -n cache-tier get secret cache-auth -o jsonpath='{.data.password}' 2>/dev/null | base64 -d 2>/dev/null)
if [ -z "$cpw" ]; then
  echo "❌ the cache side has no Secret cache-auth with a password in namespace cache-tier"
  exit 1
fi
if kubectl -n "$NS" get secret cache-auth >/dev/null 2>&1; then
  echo "❌ Secret cache-auth does not belong in namespace $NS, the cache runs in cache-tier"
  exit 1
fi
echo "✅ both Secrets exist, each in its own namespace"

if ! kubectl -n cache-tier wait --for=condition=Available deploy/inventory-cache --timeout=45s >/dev/null 2>&1; then
  echo "❌ inventory-cache in cache-tier is not available yet"
  kubectl -n cache-tier get pods --no-headers 2>/dev/null | sed 's/^/   /'
  exit 1
fi
echo "✅ inventory-cache is Ready"

good=""
for i in $(seq 1 12); do
  pod=$(../_fixtures/live-pods.sh app=inventory-sync | head -1)
  if [ -n "$pod" ]; then
    ready=$(kubectl -n "$NS" get pod "$pod" -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)
    last=$(kubectl -n "$NS" logs "$pod" --tail=2 2>/dev/null)
    if [ "$ready" = "true" ] && [ "$(echo "$last" | grep -c 'PONG ok')" -ge 2 ]; then
      good=$pod
      break
    fi
  fi
  sleep 5
done
if [ -z "$good" ]; then
  echo "❌ inventory-sync is not yet getting authenticated answers from the cache"
  exit 1
fi
echo "✅ inventory-sync ($good) gets PONG ok from the real cache"
exit 0
exit 1
