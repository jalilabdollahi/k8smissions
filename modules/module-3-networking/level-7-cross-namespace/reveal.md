## What went wrong

CoreDNS resolves short names by appending the pod's own namespace: `api-service` becomes `api-service.k8smissions.svc.cluster.local`. No such Service exists there — it is in `backend-ns`. The lookup fails.

## Fix

In manifest.yaml, change the frontend-app command to use the FQDN:

```yaml
command: ['sh', '-c', 'while true; do wget -q -O- http://api-service.backend-ns.svc.cluster.local 2>&1; sleep 5; done']
```

## DNS format for cross-namespace access

```
<service-name>.<namespace>.svc.cluster.local
```

This format always works regardless of which namespace the caller is in. Short names only work within the same namespace.