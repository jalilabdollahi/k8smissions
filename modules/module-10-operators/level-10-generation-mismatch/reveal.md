## What went wrong

`metadata.generation` is incremented by Kubernetes every time the resource spec changes. An operator should read `generation`, reconcile the spec, then write `status.observedGeneration = generation`. On the next reconcile loop, if `observedGeneration == generation`, the operator can skip — nothing changed in the spec since the last reconcile.

## Fix

```yaml
status:
  phase: Ready
  observedGeneration: 5
```

In operator code (controller-runtime):
```go
if myApp.Generation == myApp.Status.ObservedGeneration {
    // already reconciled this generation, skip
    return ctrl.Result{}, nil
}
// ... do reconciliation ...
myApp.Status.ObservedGeneration = myApp.Generation
return ctrl.Result{}, r.Status().Update(ctx, &myApp)
```

## Why this matters

Without generation-based guards, every status change (which is a watch event) triggers a reconcile loop, which may update status again, which triggers another reconcile — a tight feedback loop burning API server quota. `generation` only increments on spec changes (not status changes), making it the correct signal for 'does the operator need to act'. Status-only changes don't increment `generation`, so the guard correctly skips them.