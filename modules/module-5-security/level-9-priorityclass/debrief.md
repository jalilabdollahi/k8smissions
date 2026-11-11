## What was broken

`checkout` had a PriorityClass with a high value, yet it stayed Pending next to low-priority `batch-reindex` pods that were using all the CPU. The class `platform-critical` was created with `preemptionPolicy: Never`.

## Evidence

`describe pod` only said `0/3 nodes are available: Insufficient cpu`, with no line about preemption. `get priorityclass` shows the value; the policy is in `-o yaml` (or `-o custom-columns=NAME:.metadata.name,VALUE:.value,POLICY:.preemptionPolicy`). The pod's `.spec.priority` was already 100000, so the value was never the problem.

## Why Kubernetes behaved this way

Priority does two jobs. It orders the scheduling queue, and with `PreemptLowerPriority` (the default) it lets the scheduler evict lower-priority pods that stand in the way. With `Never`, the pod is queued ahead of others but waits for room like any other pod. This is meant for long-running data jobs that should go first without disturbing anyone.

PriorityClass `value`, `preemptionPolicy` and `globalDefault` cannot be edited after creation, so editing gets an API error. Pods copy the priority value at admission: existing pods keep working if you delete and recreate a class.

## The fix

Create a new class with `PreemptLowerPriority`, switch the Deployment to it, and let the scheduler evict batch pods as needed. The Deployment rollout then creates pods that preempt `batch-reindex`.

## In production

Reserve very high values for a few platform classes, never set `globalDefault: true` casually (every pod without a class takes that priority), and remember preempted pods get their grace period before the room is free. Pair critical classes with PodDisruptionBudgets for what must not be evicted.

## Commands worth remembering

- `kubectl get priorityclass -o custom-columns=NAME:.metadata.name,VALUE:.value,POLICY:.preemptionPolicy`
- `kubectl get pod <pod> -o jsonpath='{.spec.priority} {.spec.preemptionPolicy}'`
- `kubectl explain priorityclass`
