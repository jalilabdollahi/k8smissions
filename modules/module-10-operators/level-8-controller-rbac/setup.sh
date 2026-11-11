#!/bin/bash
. ../_fixtures/lib.sh
install_kapi

apply_managed <<'Y'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: reports.audit.acme.io
spec:
  group: audit.acme.io
  scope: Namespaced
  names: {kind: Report, plural: reports, singular: report}
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
              title: {type: string}
          status:
            type: object
            properties:
              phase: {type: string}
              summary: {type: string}
Y
wait_crd reports.audit.acme.io
kubectl -n "$NS" apply -f - >/dev/null <<'Y'
apiVersion: audit.acme.io/v1
kind: Report
metadata: {name: q3-capacity}
spec: {title: "Q3 capacity review"}
---
apiVersion: audit.acme.io/v1
kind: Report
metadata: {name: q3-access}
spec: {title: "Q3 access review"}
---
apiVersion: audit.acme.io/v1
kind: Report
metadata: {name: q3-cost}
spec: {title: "Q3 cost review"}
Y
