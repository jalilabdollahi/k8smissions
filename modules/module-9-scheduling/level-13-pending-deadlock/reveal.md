## What went wrong

`failurePolicy: Fail` means: if the webhook service is unreachable (timeout, service down, DNS failure), treat the admission request as a rejection. With the validator service down, 100% of pod CREATE requests fail cluster-wide — a full scheduling deadlock.

## Fix

```yaml
failurePolicy: Ignore
```

This allows pod creation to proceed even if the webhook is unreachable. Fix the underlying webhook service, then revert to `failurePolicy: Fail`.

## Why this matters

Admission webhooks sit in the critical path of every API request matching their rules. A webhook with `failurePolicy: Fail` is a cluster-wide single point of failure for all covered operations. Best practices:
- Use `failurePolicy: Ignore` for non-critical validation
- Deploy webhook services with multiple replicas and a PDB
- Use `namespaceSelector` or `objectSelector` to limit scope
- Set a short `timeoutSeconds` (3–5s) to fail fast
- Add a `objectSelector` exclusion for the `kube-system` namespace to prevent the webhook from blocking its own service pods