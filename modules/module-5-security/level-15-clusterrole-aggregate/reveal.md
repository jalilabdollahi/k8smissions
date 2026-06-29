## What went wrong

Kubernetes aggregated ClusterRoles work by continuously scanning all ClusterRoles for matching labels and merging their rules into the parent. `operator-role` looks for label `rbac.example.io/aggregate-to-operator: 'true'`. The source role has `aggregate-to-viewer` — one word off — so the selector never matches and the parent's `rules:` stays empty.

## Fix

Change the label on `deployments-reader` to match the selector:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: deployments-reader
  labels:
    rbac.example.io/aggregate-to-operator: 'true'  # was: aggregate-to-viewer
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch"]
```

Kubernetes will automatically detect the new label and merge the rules into `operator-role` within seconds — no restart required.

## Why this matters

ClusterRole aggregation is how Kubernetes itself builds the built-in `admin`, `edit`, and `view` roles — CRD controllers add permissions by labeling a ClusterRole with `rbac.authorization.k8s.io/aggregate-to-edit: 'true'`. This pattern lets you extend roles without modifying them directly, which is important in multi-tenant clusters where you don't own the parent role. The entire mechanism is label-matching, so a single character difference silently breaks it — always verify with `kubectl get clusterrole operator-role -o yaml` after applying labels to confirm the rules were merged.