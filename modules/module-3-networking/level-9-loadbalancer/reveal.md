## What went wrong

`type: LoadBalancer` requires an external load balancer controller to respond to the Service creation and assign an IP. In cloud clusters (EKS, GKE, AKS), this happens automatically. In a local kind cluster, no such controller exists — the EXTERNAL-IP stays `<pending>` indefinitely.

## Fix

In manifest.yaml, change the Service:

```yaml
spec:
  type: NodePort
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
```

Access it at `http://<node-ip>:30080`.

## When to use each type

- `ClusterIP` — internal only (default)
- `NodePort` — external access via node IP, works everywhere
- `LoadBalancer` — external access via cloud load balancer (requires cloud provider or MetalLB)
- `ExternalName` — maps to an external DNS name