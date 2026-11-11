## What was broken

Service `search` had no endpoints, but the Service was fine. Each `search-api` pod was Running yet not Ready, because its readiness probe waits for `/index/ready`, a file written by the `indexer` sidecar. The sidecar was started with `--out-dir`, which its script doesn't accept, so it exited with a usage error and restarted over and over.

## The evidence

`kubectl get endpointslices -o yaml` listed the four pod addresses with `ready: false` (or none at all). `kubectl describe pod` showed `Readiness probe failed` for `search-api` and restarts on `indexer`. `kubectl logs -c indexer --previous` printed argparse's `unrecognized arguments` message, which names the real flag.

## Why Kubernetes behaves this way

The EndpointSlice controller only publishes pods whose Ready condition is true, and a pod is Ready only when all its containers are Ready. A readiness probe is the application's way of saying "send me traffic", and here the application depends on a sibling container. The symptom appears on the Service, but the cause lives two objects away.

## The fix

Correct the sidecar's arguments in the Deployment template. Removing the probe would add the pods to the Service immediately, and they would answer 503 because the index was never built.

## In production

Follow a missing endpoint back: Service selector, then pods, then readiness, then the container whose output explains it. Read `--previous` logs for anything that restarts.

## Commands worth remembering

- `kubectl get endpointslices -l kubernetes.io/service-name=<svc> -o yaml`
- `kubectl logs <pod> -c <container> --previous`
- `kubectl describe pod <pod>` (Events and Last State)
