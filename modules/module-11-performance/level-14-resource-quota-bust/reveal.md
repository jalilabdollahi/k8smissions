## What went wrong

The namespace ResourceQuota enforces hard limits on the total resources all pods in the namespace can request. When the sum of all pod `requests.cpu` exceeds `hard.requests.cpu`, new pod creations fail at admission with a quota exceeded error.

## Fix

```yaml
spec:
  hard:
    requests.cpu: '8'
    requests.memory: 16Gi
    limits.cpu: '16'
    limits.memory: 32Gi
```

## Why this matters

ResourceQuotas are the primary mechanism for multi-tenant namespace isolation — preventing one team's workloads from consuming the entire cluster. Common pitfalls:
1. **Limits required**: if a quota for `limits.cpu` exists, every container in the namespace must set `limits.cpu` — pods without limits are rejected
2. **Quota ≠ capacity**: quota limits resource *requests*, not actual usage. Setting quota to cluster capacity doesn't prevent overcommit.
3. **Quota scope**: quotas can be scoped (e.g., only count `BestEffort` pods) to allow different rules for different QoS classes
4. **PriorityClass quotas**: use `scopeSelector: matchExpressions: [{operator: In, scopeName: PriorityClassName, values: [high-priority]}]` to set separate quotas per priority