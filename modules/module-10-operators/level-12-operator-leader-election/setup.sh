#!/bin/bash
. ../_fixtures/lib.sh
install_kapi

apply_managed <<'Y'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: orders.shop.acme.io
spec:
  group: shop.acme.io
  scope: Namespaced
  names: {kind: Order, plural: orders, singular: order}
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
              item: {type: string}
              quantity: {type: integer}
          status:
            type: object
            properties:
              phase: {type: string}
              lastWriter: {type: string}
              claims: {type: integer}
Y
wait_crd orders.shop.acme.io

kubectl -n "$NS" apply -f - >/dev/null <<'Y'
apiVersion: shop.acme.io/v1
kind: Order
metadata: {name: o-1001}
spec: {item: espresso-beans, quantity: 12}
---
apiVersion: shop.acme.io/v1
kind: Order
metadata: {name: o-1002}
spec: {item: oat-milk, quantity: 40}
---
apiVersion: shop.acme.io/v1
kind: Order
metadata: {name: o-1003}
spec: {item: paper-cups, quantity: 500}
Y
