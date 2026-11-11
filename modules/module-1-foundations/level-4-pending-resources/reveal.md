1. `kubectl describe pod report-builder` Events: `Insufficient cpu` on the workers.
2. The manifest has `requests.cpu: "1500"`, which means 1500 whole cores (it was meant as `500m`, half a core).
3. Pod resources are immutable, so delete the pod and apply the manifest again with `cpu: 500m`, keeping a request in place.
