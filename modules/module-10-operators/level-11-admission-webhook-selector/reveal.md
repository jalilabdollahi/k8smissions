## What went wrong

The webhook intercepts all pod CREATE events cluster-wide. This creates a circular dependency: kube-dns needs to start → needs the webhook → webhook needs DNS to resolve its service name → kube-dns needs to start. When the webhook is unavailable (restart, slow response) and `failurePolicy: Fail` is set, DNS pods can't be created and the entire cluster's DNS breaks.

## Fix

```yaml
webhooks:
- name: mutate.example.com
  namespaceSelector:
    matchExpressions:
    - key: kubernetes.io/metadata.name
      operator: NotIn
      values:
      - kube-system
      - kube-public
      - kube-node-lease
```

## Why this matters

Never apply admission webhooks to `kube-system` without extreme care. System components (DNS, CNI, CSI, metrics-server) must be able to create pods without passing through application-level webhooks — otherwise a webhook outage can cascade into a full cluster failure. Best practice: use `namespaceSelector` to exclude system namespaces, and use `objectSelector` to further narrow scope. The webhook should only intercept objects it actually needs to process.