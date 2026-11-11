#!/bin/bash
. ../_fixtures/lib.sh
install_kapi

apply_managed <<'Y'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: configs.settings.acme.io
spec:
  group: settings.acme.io
  scope: Namespaced
  names: {kind: Config, plural: configs, singular: config}
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
              service: {type: string}
              value: {type: string}
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
              service: {type: string}
              value: {type: string}
Y
wait_crd configs.settings.acme.io

# thirty settings written through v1alpha1, which is the storage version right now
{
  for i in $(seq -w 1 30); do
    cat <<Y
apiVersion: settings.acme.io/v1alpha1
kind: Config
metadata: {name: config-$i}
spec: {service: svc-$i, value: "setting-$i"}
---
Y
  done
} | kubectl -n "$NS" apply -f - >/dev/null
