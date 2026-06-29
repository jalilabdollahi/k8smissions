## What went wrong

`kubectl get all` is not actually 'all resources' — it queries a predefined list of resource categories. Resources are included in `kubectl get all` only if their CRD declares `categories: [all]`. Without it, the resource type is excluded from the aggregated query.

## Fix

```yaml
names:
  plural: apps
  singular: app
  kind: App
  shortNames:
  - ap
  categories:
  - all
```

## Why this matters

Categories are a CRD discovery feature that affects how `kubectl get` aggregation works. The `all` category is special — it's the list that `kubectl get all` queries. Without it, operators who run `kubectl get all` during debugging will not see your operator's CRs, potentially leading to incorrect conclusions about cluster state. Short names (`shortNames: [ap]`) allow `kubectl get ap` as a convenient alias. Both are purely client-side discovery metadata and have no impact on the API server's behavior.