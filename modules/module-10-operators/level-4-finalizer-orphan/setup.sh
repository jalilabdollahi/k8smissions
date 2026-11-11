#!/bin/bash
. ../_fixtures/lib.sh
install_kapi

apply_managed <<'Y'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: datastores.data.acme.io
spec:
  group: data.acme.io
  scope: Namespaced
  names: {kind: Datastore, plural: datastores, singular: datastore}
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              engine: {type: string}
              sizeGB: {type: integer}
Y
wait_crd datastores.data.acme.io
kubectl -n "$NS" apply -f - >/dev/null <<'Y'
apiVersion: data.acme.io/v1
kind: Datastore
metadata: {name: orders}
spec: {engine: postgres, sizeGB: 20}
Y
