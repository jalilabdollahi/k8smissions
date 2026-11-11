The `quota-guard` handler asks `asset-inventory` for the team's quota on every admission, and the inventory sleeps for `INVENTORY_DELAY` seconds before answering. A load test left it at 12, so every guarded pod waits 12 seconds (under the webhook's 30-second timeout, so it works, slowly).

Fix the cause in the inventory Deployment:

```bash
kubectl -n k8smissions set env deploy/asset-inventory INVENTORY_DELAY=0
kubectl -n k8smissions rollout status deploy/asset-inventory
```

Cutting `timeoutSeconds` below 12 would make the webhook fail closed and refuse compliant pods; `failurePolicy: Ignore` would admit over-quota pods when the call times out.
