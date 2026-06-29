## What went wrong

Kubernetes garbage collection (GC) uses `ownerReferences` to track parent-child relationships. When a parent is deleted, GC automatically deletes all owned objects. Without `ownerReferences`, the Deployment is an orphan — Kubernetes has no record of who created it, so it's never cleaned up.

## Fix

```yaml
metadata:
  ownerReferences:
  - apiVersion: example.com/v1
    kind: MyApp
    name: my-app
    uid: <uid-of-the-parent-cr>
    controller: true
    blockOwnerDeletion: true
```

In operator code (controller-runtime):
```go
ctrlutil.SetControllerReference(&myApp, &deployment, r.Scheme)
```

## Why this matters

`controller: true` means this object has exactly one controller owner (prevents multiple controllers fighting). `blockOwnerDeletion: true` means the parent's deletion is blocked until this child is deleted first, ensuring clean ordering. The `uid` must match the parent CR's actual UID — not a placeholder. Without ownerReferences, every operator deployment creates resource leaks: delete a hundred CRs over time and you'll have a hundred orphaned Deployments. Always set ownerReferences on every resource an operator creates.