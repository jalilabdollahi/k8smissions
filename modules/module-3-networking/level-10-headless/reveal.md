## What went wrong

The Service has a real clusterIP. Kubernetes only creates per-pod DNS records (`web-0.web-cluster.k8smissions.svc.cluster.local`) when the Service is headless (`clusterIP: None`). With a regular ClusterIP Service, DNS only resolves the virtual IP — you cannot address individual pods by name.

## Fix

In manifest.yaml, change the Service:

```yaml
spec:
  clusterIP: None   # headless
  selector:
    app: web-cluster
  ports:
  - port: 80
    targetPort: 80
```

Before applying, delete the old Service:

```bash
kubectl delete service web-cluster -n k8smissions
```

Kubernetes does not allow changing clusterIP on an existing Service.

## What headless gives you

- `web-cluster.k8smissions.svc.cluster.local` → returns all pod IPs (round-robin)
- `web-0.web-cluster.k8smissions.svc.cluster.local` → returns exactly pod web-0's IP