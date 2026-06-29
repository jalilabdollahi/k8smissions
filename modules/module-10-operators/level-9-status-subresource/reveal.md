## What went wrong

In Kubernetes, the `status` subresource is separate from the main resource endpoint. Without `subresources: {status: {}}` in the CRD, the `/status` endpoint doesn't exist. Patches that include `status` are accepted by the main endpoint but the status field is stripped out (Kubernetes ignores status updates on the main resource endpoint by design).

## Fix

```yaml
versions:
- name: v1
  served: true
  storage: true
  schema:
    openAPIV3Schema: ...
  subresources:
    status: {}
```

## Why this matters

The status subresource separation exists for good reason: it prevents users from manually overwriting operator-managed status, and it allows different RBAC permissions for spec updates (user-facing) vs. status updates (operator-facing). In operator code, use `client.Status().Update()` or `client.Status().Patch()` — not `client.Update()` — to write to status. Without the subresource enabled, `client.Status().Update()` calls will fail silently or error, and status will appear frozen.