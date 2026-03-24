# Common Mistakes — Forbidden Access

## Mistake 1: Using ClusterRole instead of Role for namespace-scoped access

**Wrong approach:** Creating a ClusterRole and ClusterRoleBinding when only namespace access is needed

**Correct approach:** Use Role + RoleBinding for namespace-scoped access; ClusterRole for cluster-wide

## Mistake 2: Binding role to the wrong subject kind

**Wrong approach:** Using 'kind: User' with a SA name instead of 'kind: ServiceAccount'

**Correct approach:** ServiceAccounts use kind: ServiceAccount with namespace field
