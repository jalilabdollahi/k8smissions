## What was broken

The `catalog` pods open their port instantly but answer 503 for the first 20 seconds while a price cache warms up. The Deployment had no readiness probe, so Kubernetes considered every pod Ready as soon as its container was running and added it to the Service straight away. A third of the requests then hit a cold pod.

## The evidence

`get pods` showed `1/1 Running` for a pod that could not serve. `get endpoints catalog` listed the new pod's IP immediately. The app log said "warming price cache (20s)" and a `curl` against the pod returned 503, while `/ready` reported the same state honestly.

## Why Kubernetes behaves this way

"Running" means the process started. "Ready" means "send me traffic", and it is decided by the readiness probe; with no probe, Ready is true by default. The endpoints controller only lists Ready pods, so the probe is the one lever that keeps cold pods out of rotation. Liveness is a different question (restart me); a failing readiness probe never restarts anything.

## The fix

Add a `readinessProbe` that checks the application's own warm signal, `/ready`. The new pod stays out of the endpoints until the cache is warm, and the other replicas carry the load meanwhile.

## In production

Make the readiness endpoint reflect real dependencies (cache, database connection), and keep it cheap. Combine it with `maxUnavailable: 0` rollouts so a slow warm-up never reduces capacity. Probe tuning (startup, thresholds, types) is covered in module 6.

## Commands worth remembering

- `kubectl get endpoints <svc> -w`
- `kubectl get pods -w` (watch the READY column)
- `kubectl explain pod.spec.containers.readinessProbe`
