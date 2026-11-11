## What was broken

Service `thumb-api` forwarded port 80 to `targetPort: 80` on the pods, but the thumbnail server inside the container listens on 5678 (it says so in its first log line and in its `-listen=:5678` argument). The manifest's `containerPort: 80` was just a wrong note, so nothing was listening where the Service connected.

## The evidence

`get endpoints` was populated: the selector and the readiness were fine, which pointed away from labels. `kubectl logs deploy/thumb-api` printed the real listen address. `describe service` showed `TargetPort: 80/TCP`. The client error `Connection refused` means the packet reached a pod IP, and nothing accepted it on that port.

## Why Kubernetes behaved this way

`ports[].containerPort` is informational: it feeds tools and named-port lookups, but the container can listen on anything, and Kubernetes never checks it. Traffic follows only `Service.spec.ports[].targetPort`. A readiness probe would not have noticed, because none was defined.

## The fix

Set `targetPort` to the real port. Clients keep using port 80. Because only the Service changed, the pods were left alone (no restarts).

## In production

Give the container port a name (`name: http`) and use it as `targetPort: http`, so one number lives in one place. Add a readiness probe on the real port so a mismatch shows up as "not Ready" rather than as refused connections. Named ports are covered in module 3.

## Commands worth remembering

- `kubectl describe svc <name>`
- `kubectl logs <pod>` (listen address)
- `kubectl port-forward svc/<name> 8080:80` to test from your own machine
