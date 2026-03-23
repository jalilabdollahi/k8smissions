# Never Ready

## What Was Broken
The readiness probe sent HTTP GET to `/healthz`. Default nginx doesn't have a `/healthz` endpoint — the probe received 404, so Kubernetes never marked the pods Ready. No traffic was sent to them.

## The Fix
Change `readinessProbe.httpGet.path` to `/` (or a path that nginx actually serves). For production apps, implement a dedicated `/healthz` endpoint that returns 200 only when the app is genuinely ready.

## Why It Matters
Readiness != Liveness. A failing readiness probe removes the pod from Service endpoints — traffic stops. A failing liveness probe restarts the pod. Use readiness for 'ready to accept requests', liveness for 'stuck and must be restarted'.

## Pro Tip
Check probe results live: `kubectl exec <pod> -- wget -O- http://localhost:80/healthz` to manually trigger what the kubelet does. Combined with `kubectl describe pod`, this makes probe debugging fast.

## Concepts
readiness probe, httpGet, 404 probe failure, endpoints, Service traffic
