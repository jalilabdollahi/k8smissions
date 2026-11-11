kubectl -n k8smissions get workload search-indexer -o yaml | sed -n '/^spec:/,$p'
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
kubectl -n k8smissions get workload search-indexer thumbnailer -o custom-columns=NAME:.metadata.name,OWNER:.spec.owner,CC:.spec.costCenter
