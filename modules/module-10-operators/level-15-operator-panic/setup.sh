#!/bin/bash
. ../_fixtures/lib.sh
install_kapi

# the rendered release files (what `helm template` produced) that the platform team keeps in the namespace
dir=$(mktemp -d)
cat > "$dir/crds.yaml" <<'Y'
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
              options:
                type: object
                properties:
                  retries: {type: integer}
                  timeoutSeconds: {type: integer}
          status:
            type: object
            properties:
              phase: {type: string}
              retries: {type: integer}
Y
cat > "$dir/workloads.yaml" <<'Y'
apiVersion: platform.acme.io/v1
kind: Workload
metadata: {name: api, namespace: k8smissions}
spec:
  image: registry.acme.io/api:4.2.0
  options: {retries: 3, timeoutSeconds: 30}
---
apiVersion: platform.acme.io/v1
kind: Workload
metadata: {name: worker, namespace: k8smissions}
spec:
  image: registry.acme.io/worker:4.2.0
  options: {retries: 5, timeoutSeconds: 120}
---
apiVersion: platform.acme.io/v1
kind: Workload
metadata: {name: legacy-sync, namespace: k8smissions}
spec:
  image: registry.acme.io/legacy-sync:1.9.3
Y
kubectl -n "$NS" create configmap release-manifests --from-file=crds.yaml="$dir/crds.yaml" \
  --from-file=workloads.yaml="$dir/workloads.yaml" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
rm -rf "$dir"
