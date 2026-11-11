#!/bin/bash
. ../_fixtures/lib.sh

# a CRD with no schema at all: every field is accepted and stored as it is
apply_managed <<'Y'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: workloads.platform.acme.io
spec:
  group: platform.acme.io
  scope: Namespaced
  names: {kind: Workload, plural: workloads, singular: workload}
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        x-kubernetes-preserve-unknown-fields: true
Y
wait_crd workloads.platform.acme.io
kubectl -n "$NS" apply -f - >/dev/null <<'Y'
apiVersion: platform.acme.io/v1
kind: Workload
metadata: {name: search-indexer}
spec: {replicas: 4, tier: silver, owner: search-team, costCenter: CC-4411}
---
apiVersion: platform.acme.io/v1
kind: Workload
metadata: {name: thumbnailer}
spec: {replicas: 2, tier: bronze, owner: media-team, costCenter: CC-2087}
Y
