## What went wrong

Two separate races cause request errors during shutdown:
1. **Too-short grace period**: `terminationGracePeriodSeconds: 5` kills in-flight requests that take longer than 5 seconds
2. **Load balancer lag**: when a pod receives SIGTERM, the kube-proxy/iptables update removing it from Service endpoints takes 1–3 seconds. New requests still arrive during this window.

## Fix

```yaml
terminationGracePeriodSeconds: 60
containers:
- name: web
  lifecycle:
    preStop:
      exec:
        command: ["/bin/sh", "-c", "sleep 10"]
```

## Why this matters

The graceful shutdown sequence:
1. Pod receives SIGTERM → preStop hook runs (`sleep 10`)
2. During those 10 seconds, endpoint update propagates to kube-proxy → load balancer stops routing new requests to this pod
3. After preStop completes, SIGTERM is sent to the container process → app finishes in-flight requests
4. After `terminationGracePeriodSeconds`, SIGKILL is sent

The `sleep 10` in preStop is the standard pattern for the 'endpoint propagation window'. The grace period must be longer than `preStop duration + max request duration`. For HTTP/1.1 servers, set `connection: close` headers to drain connections.