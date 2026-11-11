## What was broken

Both Deployments carried a required `podAffinity` to each other on `kubernetes.io/hostname`: web needed a node with a `tier=cache` pod, cache needed a node with a `tier=web` pod. All five pods stayed Pending.

## The evidence

Every pod's events said the node(s) "didn't match pod affinity rules", while plenty of CPU and memory was free. Reading both Deployments side by side showed that the two rules reference each other.

## Why Kubernetes behaves this way

Required pod affinity is a filter on the current state: the scheduler looks for running (or already assumed) pods that match the selector in the candidate node's topology domain. There is one exception, a pod whose own labels match its affinity selector may be the first of its kind. Two different tiers get no such exception, so a cycle never resolves by itself.

## The fix

Remove the rule from one side, so one tier schedules on its own and the other follows it. Here the cache already had its own placement (`nodeSelector pool=cache`), so it was the natural one to go first and the web keeps the co-location rule. Removing both rules would also turn everything green but would let web pods land away from the cache.

## In production

Make the dependency one-directional: the dependent tier has a required affinity to the tier it needs, and the dependency has no rule (or only a preferred one). If co-location matters in both directions, give both a shared node pool via a label instead.

## Commands worth remembering

- `kubectl describe pod <pod> | grep -A5 Events`
- `kubectl get pods -o wide -L tier`
- `kubectl explain pod.spec.affinity.podAffinity.requiredDuringSchedulingIgnoredDuringExecution`
