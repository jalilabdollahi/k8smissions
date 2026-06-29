## What went wrong

`NoExecute` taints behave differently from `NoSchedule`: they don't just block new pods — they immediately evict *running* pods that lack a matching toleration. No toleration = immediate eviction with no warning.

## Fix

```yaml
spec:
  tolerations:
  - key: maintenance
    operator: Equal
    value: draining
    effect: NoExecute
    tolerationSeconds: 300
```

`tolerationSeconds: 300` means the pod can stay on the node for 5 minutes after the taint is applied, giving it time to finish in-flight work before being evicted.

## Why this matters

The three taint effects have very different behaviors:
- `NoSchedule`: new pods without a toleration won't be placed here, but existing pods stay
- `PreferNoSchedule`: soft version of NoSchedule
- `NoExecute`: new pods blocked AND existing pods evicted immediately (unless `tolerationSeconds` is set)

Kubernetes automatically applies `NoExecute` taints for node conditions like `node.kubernetes.io/not-ready` and `node.kubernetes.io/unreachable` — which is why pods disappear when nodes go down. The built-in `tolerationSeconds: 300` default on most pods gives 5 minutes before eviction on node failure.