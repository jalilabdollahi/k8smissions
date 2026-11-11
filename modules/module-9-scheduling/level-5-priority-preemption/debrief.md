## What was broken

`pay-gateway` used PriorityClass `payments-high`: value 100000, `preemptionPolicy: Never`. Both workers were full of `dev-sandbox` pods with priority 1000, so the gateway pods could not be placed and, because of the policy, were not allowed to evict anyone. They stayed Pending, queued ahead of other pods but never making room.

## The evidence

The pod events said `Insufficient cpu` on both workers with no mention of preemption, which is what a `Never` policy looks like. `kubectl get priorityclass payments-high -o yaml` showed the policy. Priority numbers alone told nothing.

## Why Kubernetes behaves this way

Priority orders the scheduling queue; preemption is a separate permission. With `PreemptLowerPriority` (the default) the scheduler deletes enough lower-priority pods on one node to fit a Pending pod. `Never` keeps the ordering and drops the right to evict. The policy is copied into `pod.spec.preemptionPolicy` at creation, and PriorityClass `value` and `preemptionPolicy` are immutable, so editing the class or only raising the number does nothing for existing pods.

## The fix

Create a class that allows preemption, switch the Deployment to it, and let the rollout replace the pods. Deleting and recreating `payments-high` also works if you then replace the pods, but a new class name leaves a clean trail. Scaling `dev-sandbox` down by hand would have worked once and taught the scheduler nothing.

## In production

Reserve `Never` for batch jobs that should queue first without hurting anyone. Production-critical classes should preempt, and cheap classes (sandboxes, preview environments) should rank below them on purpose. Watch `Preempted` events: they are the audit trail.

## Commands worth remembering

- `kubectl get priorityclass`
- `kubectl get pod <pod> -o jsonpath='{.spec.priority} {.spec.preemptionPolicy}'`
- `kubectl get events --field-selector reason=Preempted`
