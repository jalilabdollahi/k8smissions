## What went wrong

The webhook has `timeoutSeconds: 30`, meaning the API server waits up to 30 seconds for each admission response. If the webhook makes a slow external API call (OPA policy engine, external database, DNS lookup), every pod creation is delayed by the webhook's latency.

## Fix

```yaml
timeoutSeconds: 5
```

## Why this matters

Admission webhooks sit in the synchronous path of every API operation matching their rules. High `timeoutSeconds` values multiply across every pod creation in a busy cluster. The Kubernetes maximum is 30 seconds; the recommended range is 3–10 seconds. Better solutions for slow validation logic:
1. Reduce the webhook's work — cache expensive lookups
2. Use async validation — admit immediately, validate asynchronously, update status
3. Set `failurePolicy: Ignore` so timeouts don't block creation (but do log/alert)
4. Use more specific `rules` to reduce the number of objects the webhook must process