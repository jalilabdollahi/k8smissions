#!/bin/bash
. ../_fixtures/lib.sh
install_kapi

apply_managed <<'Y'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: widgets.widgets.acme.io
spec:
  group: widgets.acme.io
  scope: Namespaced
  names: {kind: Widget, plural: widgets, singular: widget}
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
              replicas: {type: integer, description: "legacy, replaced by sizing.replicas"}
              sizing:
                type: object
                properties:
                  replicas: {type: integer}
          status:
            type: object
            properties:
              schemaVersion: {type: integer}
              operatorVersion: {type: string}
              phase: {type: string}
Y
wait_crd widgets.widgets.acme.io
for row in "gauge 2" "dial 1" "meter 3"; do
  set -- $row
  kubectl -n "$NS" apply -f - >/dev/null <<Y
apiVersion: widgets.acme.io/v1
kind: Widget
metadata: {name: $1}
spec: {replicas: $2}
Y
done
