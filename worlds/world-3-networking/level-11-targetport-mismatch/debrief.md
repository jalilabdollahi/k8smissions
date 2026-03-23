# Connection Refused

## What Was Broken
The Service `targetPort` was 8080 but the nginx container actually listens on port 80. kube-proxy forwarded traffic to port 8080 on the pod's network namespace — which refused connections.

## The Fix
Set `targetPort` to match the container's actual listening port (80 for nginx). targetPort can be a port number or the name of a `containerPort` in the pod spec.

## Why It Matters
targetPort mismatch is one of the most common Kubernetes networking bugs. `kubectl get endpoints` is the fastest diagnostic: if it shows `<none>`, no healthy pods matched. If it shows IPs but traffic still fails, targetPort is likely wrong.

## Pro Tip
Named ports make configs more resilient: define `name: http` on the containerPort, then use `targetPort: http` in the Service. If you change the port number later, you only update the pod spec.

## Concepts
Service, targetPort, containerPort, endpoints, kube-proxy
