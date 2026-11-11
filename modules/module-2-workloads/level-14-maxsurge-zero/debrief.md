## What was broken

`api-server` binds `hostPort: 9000` on each of two nodes, so every node can hold exactly one of its pods. The default rolling update wanted to create a third pod before deleting an old one, and there was no node with a free port for it.

## The evidence

One pod stayed `Pending`, and `describe pod` showed `0/3 nodes are available: ... didn't have free ports for the requested pod ports`. The Deployment status showed one updated replica and two old ones. Deleting the Pending pod only created another.

## Why Kubernetes behaves this way

With `replicas: 2`, the default `maxSurge: 25%` rounds up to one extra pod and `maxUnavailable: 25%` rounds down to zero. The controller therefore must have three pods at the peak, and zero unavailable means it cannot stop an old pod to make room. Scheduling a pod that needs an exclusive port is exactly the case where surge needs capacity that does not exist.

## The fix

Set `maxSurge: 0` and `maxUnavailable: 1`. The controller deletes one old pod first, the port frees, the new pod starts, and then it repeats with the other. Capacity drops to one pod during each step, which is fine with two replicas and a readiness probe. Both values at zero would be rejected by the API.

## In production

`hostPort` makes capacity part of the rollout. Prefer a DaemonSet for node-local agents, or a `NodePort`/Service for the traffic. If you must keep hostPort, size the strategy to the number of nodes.

## Commands worth remembering

- `kubectl describe pod <name>` (scheduler events)
- `kubectl explain deployment.spec.strategy.rollingUpdate`
- `kubectl rollout status deployment/<name>`
