## What went wrong

The app tries to connect to the hostname `database`, which is the pod's name. CoreDNS does not create DNS entries for pod names (unless configured separately). It only creates entries for Services. The Service is named `database-service`, so that is the correct hostname to use.

## Fix

In manifest.yaml, change the app-client command:

```yaml
args:
- |
  while true; do
    pg_isready -h database-service -p 5432 || echo "Connection failed"
    sleep 10
  done
```

## How Kubernetes DNS works

When you create a Service, CoreDNS registers: `<service-name>.<namespace>.svc.cluster.local`. Within the same namespace, the short name `<service-name>` also resolves. Pod names are never registered in DNS unless you use a headless Service.