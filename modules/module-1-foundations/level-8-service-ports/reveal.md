## What went wrong

The Service has `targetPort: 8080`, but nginx is listening on port 80. When traffic arrives at the Service, it gets forwarded to port 8080 on the pod — where nothing is listening. Connection refused.

## Fix

In manifest.yaml, under the Service ports section:

```yaml
ports:
- port: 80
  targetPort: 80
```

## The difference between port and targetPort

- `port` — the port the Service exposes to clients inside the cluster
- `targetPort` — the port on the Pod the traffic is forwarded to (must match containerPort)