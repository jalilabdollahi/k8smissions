#!/bin/bash
. ../_fixtures/lib.sh
install_kapi

apply_managed <<'Y'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: sites.web.acme.io
spec:
  group: web.acme.io
  scope: Namespaced
  names: {kind: Site, plural: sites, singular: site}
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
              host: {type: string}
Y
wait_crd sites.web.acme.io

kubectl -n "$NS" apply -f - >/dev/null <<'Y'
apiVersion: web.acme.io/v1
kind: Site
metadata: {name: storefront}
spec: {host: shop.acme.io}
---
apiVersion: web.acme.io/v1
kind: Site
metadata: {name: blog}
spec: {host: blog.acme.io}
Y
