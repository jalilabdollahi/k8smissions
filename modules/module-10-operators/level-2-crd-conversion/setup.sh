#!/bin/bash
. ../_fixtures/lib.sh
lab_ns
install_kapi
install_webhook_server
tls_secret converter-tls good
ca_secret converter-ca ca-a

# Two served versions, stored as v1alpha1, and no conversion configured yet.
apply_managed <<'Y'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: caches.cache.acme.io
spec:
  group: cache.acme.io
  scope: Namespaced
  names: {kind: Cache, plural: caches, singular: cache}
  conversion:
    strategy: None
  versions:
  - name: v1alpha1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              maxMemoryMB: {type: integer}
              evictionPolicy: {type: string}
  - name: v1
    served: true
    storage: false
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              memory: {type: string}
              evictionPolicy: {type: string}
Y
wait_crd caches.cache.acme.io
for row in "sessions 512 allkeys-lru" "catalog 1024 volatile-ttl" "ratelimits 128 noeviction"; do
  set -- $row
  kubectl -n "$NS" apply -f - >/dev/null <<Y
apiVersion: cache.acme.io/v1alpha1
kind: Cache
metadata: {name: $1}
spec: {maxMemoryMB: $2, evictionPolicy: $3}
Y
done
