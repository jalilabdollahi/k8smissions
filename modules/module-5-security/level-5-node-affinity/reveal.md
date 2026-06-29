## What went wrong

The pod requires a node with label `gpu-type=nvidia-tesla`. The actual node has label `accelerator=gpu`. Neither the key (`gpu-type`) nor the value (`nvidia-tesla`) matches, so no node satisfies the required affinity and the pod stays Pending indefinitely.

## Fix

Update the affinity to match the actual node labels:

```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: accelerator
          operator: In
          values:
          - gpu
```

## Why this matters

`requiredDuringSchedulingIgnoredDuringExecution` is a hard constraint: if no node matches, the pod will never schedule — it waits forever without error messages in the pod status itself. Always verify node labels with `kubectl get nodes --show-labels` before writing affinity rules. For non-critical placement preferences, use `preferredDuringSchedulingIgnoredDuringExecution` instead, which degrades gracefully.