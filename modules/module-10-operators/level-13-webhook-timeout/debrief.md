## What was broken

Admission of every guarded pod waited about 12 seconds because the webhook handler calls `asset-inventory` synchronously, and a leftover load-test setting (`INVENTORY_DELAY=12`) made that service slow. Nothing failed: 12 seconds is below the webhook's 30-second `timeoutSeconds`, so every request was eventually allowed or denied correctly.

## The evidence

`time kubectl run ... --dry-run=server` showed the delay; the `quota-guard` log showed one line per request; the `asset-inventory` log said `served /quota/payments after 12s delay`, and its Deployment had the env var that set it.

## Why Kubernetes behaved this way

Admission webhooks are synchronous: the API request does not complete until every matching webhook answers or times out. The webhook's latency budget is therefore the latency of whatever its handler depends on. `timeoutSeconds` only decides how long the API server waits, and `failurePolicy` decides what a timeout means: with `Fail` it is a refusal, with `Ignore` the request goes through unchecked.

So both tempting shortcuts are wrong here. A timeout of 5 seconds with `Fail` turns "slow" into "every compliant pod is rejected"; `Ignore` makes it fast but also silently admits over-quota pods whenever the inventory is slow, which is exactly when a quota matters. The slowness has to be removed where it starts.

## In production

Keep webhook handlers local and fast: cache the quota data, or use a ValidatingAdmissionPolicy (CEL) for rules that need no external call. Set `timeoutSeconds` to a few seconds, alert on `apiserver_admission_webhook_admission_duration_seconds`, and run the server with several replicas.

## Worth remembering

- `kubectl get --raw /metrics | grep admission_webhook_admission_duration`
- `kubectl run x --image=busybox --dry-run=server` exercises admission without creating anything.
- `kubectl set env deploy/<name> --list` shows what a Deployment injects into its pods.
