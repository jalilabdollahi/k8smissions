#!/bin/bash
. ../_fixtures/lib.sh

apply_managed <<'Y'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: invoicebatches.billing.acme.io
spec:
  group: billing.acme.io
  scope: Namespaced
  names: {kind: InvoiceBatch, plural: invoicebatches, singular: invoicebatch}
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
              customer: {type: string}
              invoices: {type: integer}
          status:
            type: object
            properties:
              state: {type: string}
              progress: {type: string}
Y
wait_crd invoicebatches.billing.acme.io

n=0
for row in "acme-retail Failed 0/120" "northwind Running 58/90" "globex Failed 14/300" "initech Done 75/75" \
           "umbrella Failed 0/42" "hooli Running 210/400" "stark Failed 66/66" "wayne Done 18/18"; do
  set -- $row
  n=$((n + 1))
  kubectl -n "$NS" apply -f - >/dev/null <<Y
apiVersion: billing.acme.io/v1
kind: InvoiceBatch
metadata: {name: batch-2026-0$n}
spec: {customer: $1, invoices: ${3#*/}}
status: {state: $2, progress: "$3"}
Y
done
