# Forbidden Access

## What Was Broken
The ServiceAccount `config-reader-sa` had no Role or RoleBinding. By default, service accounts have no permissions except in namespaces that grant the default SA extra access. The pod received 403 when calling the Kubernetes API.

## The Fix
Create a Role granting the needed verbs on the needed resources, then bind it to the ServiceAccount via a RoleBinding.

## Why It Matters
Always use least-privilege RBAC: grant only the verbs and resources strictly required. For read-only needs: `get`, `list`, `watch`. Never use wildcard `*` in production. Use `kubectl auth can-i` to verify permissions before deploying.

## Pro Tip
`kubectl auth can-i --list --as=system:serviceaccount:ns:sa-name` shows all permissions for a SA. Use this for auditing. `kubectl create role` and `kubectl create rolebinding` support --dry-run=client -o yaml to scaffold correct YAML.

## Concepts
ServiceAccount, Role, RoleBinding, RBAC, 403 Forbidden, least privilege
