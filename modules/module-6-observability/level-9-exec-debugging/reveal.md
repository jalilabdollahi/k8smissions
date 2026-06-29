## What went wrong

The ConfigMap contains `"DB_HOST": "10.0.0.99"` — a hardcoded pod IP. Pod IPs are ephemeral: they are assigned at creation and released on deletion. The IP that was valid when the ConfigMap was written may belong to a completely different pod or be unroutable now.

## Fix

Update the ConfigMap to use the Service DNS name:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: k8smissions
data:
  config.json: '{"DB_HOST":"database.k8smissions.svc.cluster.local","DB_PORT":5432}'
```

## Why this matters

Kubernetes Services provide stable DNS names that survive pod restarts. The full DNS format is `<service-name>.<namespace>.svc.cluster.local`. Within the same namespace, `<service-name>` alone is sufficient. `kubectl exec` is the primary tool for live debugging — running commands inside a container without restarting it. For containers without shells (distroless images), use `kubectl debug` to attach an ephemeral sidecar container with debugging tools.