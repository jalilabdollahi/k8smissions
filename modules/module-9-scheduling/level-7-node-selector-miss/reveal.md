## What went wrong

`nodeSelector` is a hard constraint: the pod only schedules on nodes that have every key-value pair in the selector. The label `accelerator-type: nvidia-v100` doesn't exist on any node, so no valid placement exists and the pod stays Pending indefinitely.

## Fix

Remove the `nodeSelector` block:
```yaml
spec:
  # nodeSelector removed — schedules on any node
  containers:
  - name: trainer
    ...
```

Or label the correct node if GPU nodes exist:
```bash
kubectl label node <gpu-node-name> accelerator-type=nvidia-v100
```

## Why this matters

`nodeSelector` is the simplest form of node targeting — it's a map of required labels. For more flexibility, use `nodeAffinity` which supports operators (`In`, `NotIn`, `Exists`, `DoesNotExist`) and preferred vs. required semantics. Both `nodeSelector` and `nodeAffinity` are complementary: if both are specified, a node must satisfy both. Always verify node labels before writing selectors using `kubectl get nodes --show-labels`.