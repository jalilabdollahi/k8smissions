## What went wrong

No `nodePort` was specified. Kubernetes assigns a random available port in the 30000–32767 range. This changes if the Service is deleted and recreated, breaking any external configuration that expected a specific port.

## Fix

In manifest.yaml, add an explicit nodePort:

```yaml
ports:
- protocol: TCP
  port: 80
  targetPort: 80
  nodePort: 30080
```

## NodePort valid range

NodePorts must be in the range 30000–32767. Below 30000 is reserved for system services. Above 32767 is not allocated for NodePorts. If you try to set a port outside this range, the API server will reject it with a validation error.