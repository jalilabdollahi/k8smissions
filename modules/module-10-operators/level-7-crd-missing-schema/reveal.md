The CRD's schema is only `x-kubernetes-preserve-unknown-fields: true`, so nothing is validated. Add a real schema for `spec`, and declare `owner` and `costCenter` as well, because once a schema exists, every undeclared field is pruned as unknown:

```bash
kubectl apply -f - <<'Y'
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
        properties:
          spec:
            type: object
            required: [replicas, tier]
            properties:
              replicas: {type: integer, minimum: 0}
              tier: {type: string, enum: [bronze, silver, gold]}
              owner: {type: string}
              costCenter: {type: string}
Y
```

Keeping `x-kubernetes-preserve-unknown-fields: true` on `spec` (next to the typed `replicas` and `tier`) is an equally valid way to keep the bookkeeping fields.
