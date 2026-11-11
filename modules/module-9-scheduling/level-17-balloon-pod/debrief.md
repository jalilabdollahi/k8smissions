## What was broken

`capacity-reserve` is overprovisioning: pause pods that hold CPU so that a traffic spike finds warm room. That only works if the placeholders leave when a real pod needs the room. They had the same priority as `checkout` (0), so the scheduler had nobody it was allowed to evict, and `checkout` stayed Pending.

## The evidence

`kubectl top nodes` said 8% CPU, which is what the processes use. `kubectl describe node` listed requests close to 100%, which is what the scheduler counts. The pods holding it were all `capacity-reserve`, doing nothing. `FailedScheduling` mentioned `Insufficient cpu` and a preemption attempt that found no victims.

## Why Kubernetes behaves this way

The scheduler ignores utilisation: it subtracts requests from allocatable. Preemption only considers pods with strictly lower priority than the pending pod. The fix therefore sits on the victim side: a PriorityClass with a negative value for the placeholders, so any real workload outranks them.

## The fix

Create the `overprovisioning` class (value -10, not global default), set it on the placeholder Deployment, and let the rollout recreate the pods (the Deployment uses `Recreate`: a rolling update would be stuck, because the old priority-0 placeholders cannot be preempted). `checkout` now outranks the placeholders, so it takes the room it needs and the rest stays as headroom. Making the placeholders smaller would also work; deleting them would leave no headroom for the next spike.

## In production

The cluster-autoscaler overprovisioning pattern is exactly this: low-priority pause pods that cause a scale-up before real traffic arrives, and preempted pods immediately cause new nodes to be added. Mind `globalDefault`: a negative global default would lower every unlabelled pod.

## Commands worth remembering

- `kubectl top nodes` and `kubectl describe node | grep -A8 'Allocated resources'`
- `kubectl get pod -o custom-columns=N:.metadata.name,PRIO:.spec.priority`
- `kubectl get events --field-selector reason=Preempted`
