#!/bin/bash
. ../_fixtures/lib.sh
install_kapi

apply_managed <<'Y'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: inventories.stock.acme.io
spec:
  group: stock.acme.io
  scope: Namespaced
  names: {kind: Inventory, plural: inventories, singular: inventory}
  versions:
  - name: v1
    served: true
    storage: true
    subresources:
      status: {}
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              sku: {type: string}
              reorderLevel: {type: integer}
          status:
            type: object
            properties:
              phase: {type: string}
              observedGeneration: {type: integer}
              lastSync: {type: string}
Y
wait_crd inventories.stock.acme.io

kubectl -n "$NS" apply -f - >/dev/null <<'Y'
apiVersion: stock.acme.io/v1
kind: Inventory
metadata: {name: stock-eu}
spec: {sku: EU-4411, reorderLevel: 40}
---
apiVersion: stock.acme.io/v1
kind: Inventory
metadata: {name: stock-us}
spec: {sku: US-9020, reorderLevel: 25}
Y
