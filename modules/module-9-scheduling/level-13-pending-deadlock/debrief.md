## What was broken

`train-a` and `train-b` each need three pods running at the same moment, and the cluster has room for four. The Job controller created pods for both, the scheduler placed two of each, and the third pod of each Job could not fit. The running pods wait at their barrier for a peer that cannot start until somebody leaves.

## The evidence

`kubectl get pod -o wide` showed 2 Running and 1 Pending per Job. `describe pod` said `Insufficient cpu` for the Pending pods, and the logs of the running ones said `2 of 3 peers running`. Neither Job had an error: a deadlock has no failing component.

## Why Kubernetes behaves this way

The scheduler places pods one by one with no idea that they belong together. It has no gang scheduling, so a job that needs all-or-nothing can be half placed. Two half-placed jobs hold exactly the resources the other one needs.

## The fix

Serialise the work. `spec.suspend: true` on one Job deletes its pods and gives their room back; the other Job finishes, and resuming the first lets it run alone. Reducing parallelism of both would only break the barrier, and the validator looks for 3 of 3 peers in the logs.

## In production

Use a queueing layer (Kueue, Volcano, or at least `suspend` driven by a controller) so whole jobs are admitted atomically. PriorityClass preemption can also break a tie, but it kills running work. Quotas per team stop one tenant from half-filling a cluster.

## Commands worth remembering

- `kubectl patch job <name> --type=merge -p '{"spec":{"suspend":true}}'`
- `kubectl wait --for=condition=complete job/<name>`
- `kubectl get pod -l app=trainer -o wide`
