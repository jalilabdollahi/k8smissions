#!/bin/bash
. ../_fixtures/lib.sh
install_kapi

apply_managed <<'Y'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: webapps.apps.acme.io
spec:
  group: apps.acme.io
  scope: Namespaced
  names: {kind: WebApp, plural: webapps, singular: webapp}
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
              image: {type: string}
              replicas: {type: integer, minimum: 1}
          status:
            type: object
            properties:
              phase: {type: string}
              readyReplicas: {type: integer}
Y
wait_crd webapps.apps.acme.io
for row in "site-a 1" "site-b 2"; do
  set -- $row
  kubectl -n "$NS" apply -f - >/dev/null <<Y
apiVersion: apps.acme.io/v1
kind: WebApp
metadata: {name: $1}
spec: {image: "nginx:1.27-alpine", replicas: $2}
Y
  kubectl -n "$NS" patch webapp "$1" --subresource=status --type=merge -p '{"status":{"phase":"Pending"}}' >/dev/null
done
