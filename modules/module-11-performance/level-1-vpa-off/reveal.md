## What went wrong

VPA `updateMode: Off` is a read-only mode — the VPA admission controller does not mutate pod requests. This is useful for auditing what VPA *would* recommend without actually changing anything. With `Off`, OOMKills continue even when the VPA clearly shows the pod needs more memory, because no mechanism applies the recommendation.

## Fix

```yaml
updatePolicy:
  updateMode: Auto
```

## Why this matters

VPA has four modes:
- `Off`: recommendations only, never applied
- `Initial`: applied only at pod creation, never updated
- `Recreate`: applied at creation and by evicting live pods
- `Auto`: same as Recreate today (may support in-place updates in future)

`Auto` is the production-ready mode — VPA evicts pods that are significantly over- or under-resourced and lets the Deployment controller replace them with correctly-sized ones. Pair VPA with a PodDisruptionBudget to control eviction rate and prevent all pods from being evicted simultaneously.