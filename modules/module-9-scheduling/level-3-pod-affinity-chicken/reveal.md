## What went wrong

`requiredDuringSchedulingIgnoredDuringExecution` is a hard constraint: if the condition can't be met, the pod stays Pending forever. Requiring colocation with a pod that doesn't exist yet creates a chicken-and-egg deadlock.

## Fix

```yaml
spec:
  affinity:
    podAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchLabels:
              tier: cache
          topologyKey: kubernetes.io/hostname
```

## Why this matters

The naming is long but the distinction matters:
- `required`: hard constraint — pod stays Pending if unmet
- `preferred`: soft constraint — scheduler tries to satisfy it but schedules anyway if it can't

Use `required` only when the placement constraint is a hard correctness requirement (e.g., a pod that literally cannot function without a local cache sidecar). Use `preferred` for performance optimization — scheduling near a cache pod is faster, but not necessary for correctness. When in doubt, start with `preferred` and only upgrade to `required` if you're sure the target pod will always exist first.