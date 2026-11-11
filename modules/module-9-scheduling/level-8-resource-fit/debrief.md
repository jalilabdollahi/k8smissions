## What was broken

Each `video-encoder` replica requested about 60% of a worker's free CPU. Two replicas fit, one per worker. The third needed 60% on some single node, and no node had more than 40% left.

## The evidence

The Pending pod's event said `Insufficient cpu` for both workers, while the dashboards showed low CPU usage. `kubectl describe node` listed the requests already reserved, which is what the scheduler adds up. Free capacity is also not additive: 40% here and 40% there is not 80% anywhere.

## Why Kubernetes behaves this way

The scheduler's `NodeResourcesFit` filter compares a pod's request with `allocatable minus the requests of pods already on that node`, one node at a time. Real utilisation is ignored, and so is the cluster total. Large pods therefore suffer bin-packing fragmentation: free space that is too scattered to use.

## The fix

Reduce the request so two replicas can share a node (`kubectl set resources --requests=cpu=...`). The new value must stay realistic, because a request that is too small makes the pod noisy and starved on a busy node. Scaling to 2 replicas passes the Pending check and fails the capacity target; adding a node is the right answer when requests are honest and there is truly not enough room.

## In production

Right-size requests from measured usage (`kubectl top pod`, or a VPA recommendation), and prefer several smaller replicas over a few huge ones when the workload allows it, since they pack better. Cluster autoscalers solve fragmentation by adding a node once a pod is unschedulable.

A rollout needs room too: the smaller pods only fit once an old pod has gone, which is why this Deployment allows `maxUnavailable: 2`.

## Commands worth remembering

- `kubectl describe node <node> | grep -A8 "Allocated resources"`
- `kubectl set resources deploy/<name> --requests=cpu=<value>`
- `kubectl get pods -o wide`
