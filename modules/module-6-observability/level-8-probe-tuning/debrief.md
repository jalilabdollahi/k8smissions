## What was broken

`search-api` is single threaded: a request in progress blocks every other one, including the kubelet's health checks. The load generator keeps three searches in flight per replica, each 600 ms of work, so a probe waits 1.5 seconds or more. Both probes had the default `timeoutSeconds: 1`, so they failed on every attempt.

## The evidence

The events on the pod said `Liveness probe failed ... context deadline exceeded (Client.Timeout exceeded while awaiting headers)` and `Readiness probe failed`, not a connection error or a bad status. The failure was slowness, not absence. Timing the endpoint with `wget` from a neighbour pod gave the latency directly, and the app log was clean.

## Why Kubernetes behaves this way

The kubelet opens a connection, sends the request and gives up after `timeoutSeconds`. A timeout counts as a failed probe. After `failureThreshold` consecutive failures a readiness probe removes the pod from Service endpoints and a liveness probe restarts the container. Because the latency is persistent under load rather than a rare spike, more retries (`failureThreshold`) would not help: every attempt would fail.

## The fix

Raise `timeoutSeconds` on both probes above the real worst-case latency, with margin. Deleting the generator, or the probes, only hides the capacity problem.

## In production

Serve health endpoints from a separate thread or port so a busy request path cannot starve them, and size the timeout from measured p99 latency. Restarting a pod under load makes the load worse for the others.

## Commands worth remembering

- `kubectl describe pod <pod>` (Events: Unhealthy)
- `kubectl exec <pod> -- sh -c 'time wget -q -O /dev/null <url>'`
- `kubectl explain pod.spec.containers.livenessProbe`
