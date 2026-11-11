## What was broken

Three Deployments were restarting for three different reasons. `cart-cache` allocated 192 MB under a 128Mi memory limit inherited from the namespace LimitRange and was OOM-killed. `cart-worker` read a wrong queue port from its environment, could not connect, and exited with code 3 by itself. `cart-reporter` ran fine, but its liveness probe dialled a port nothing listened on, so the kubelet killed it.

## The evidence

`kubectl describe pod` shows each container's Last State. The cache says `Reason: OOMKilled`. The worker says `Reason: Error, Exit Code: 3`, and `logs --previous` carries its own message. The reporter ends with exit code 137 too, but its Reason is `Error` and the events show `Unhealthy: Liveness probe failed` followed by `Killing`. Two of the three share exit code 137, so the code alone cannot decide; the Reason and the events can.

## Why Kubernetes behaves this way

137 is 128 + SIGKILL(9). The kernel's OOM killer and the kubelet's forced stop after a failed liveness probe both end in SIGKILL; only the kubelet knows which one it was. A LimitRange fills in the default limit and rejects anything above its `max`, which is why the memory limit could not simply be raised.

## The fix

Make the cache fit (configuration, since the ceiling is a policy), correct the worker's queue address, and point the probe at the port the app listens on.

## In production

Alert on `kube_pod_container_status_last_terminated_reason` and keep one dashboard that separates OOMKilled, Error and liveness kills. Fix the cause that the evidence shows, not the symptom that is shared (the restart).

## Commands worth remembering

- `kubectl get pod <pod> -o jsonpath='{.status.containerStatuses[*].lastState}'`
- `kubectl get events --field-selector type=Warning --sort-by=.lastTimestamp`
- `kubectl describe limitrange`
