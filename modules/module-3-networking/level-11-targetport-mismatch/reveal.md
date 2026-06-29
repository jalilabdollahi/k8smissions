## What went wrong

`targetPort: 8080` tells the Service to forward incoming traffic to port 8080 on the pod. But nginx listens on port 80. The kernel on the pod receives a connection on 8080, finds no listener, and sends TCP RST — connection refused.

## Fix

In manifest.yaml, align targetPort with the container's actual port:

```yaml
ports:
- port: 80
  targetPort: 80
```

## Port fields in a Service

- `port` — what clients connect to on the Service's ClusterIP
- `targetPort` — what port traffic is forwarded to on the pod (must match containerPort or the named port)
- `nodePort` — (NodePort Services only) the port opened on every node's external interface