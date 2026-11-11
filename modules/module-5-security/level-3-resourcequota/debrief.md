## What was broken

`invoice-api` asked for 3 replicas, but the namespace ResourceQuota `team-quota` limits total `limits.cpu` and `limits.memory`. When a quota covers a compute resource, the API server rejects any pod that does not declare it. The pod was never created, so there was nothing to be Pending, and `get pods` and `describe pod` had nothing to show.

## Evidence

The ReplicaSet controller creates the pods, so the refusal is recorded on the ReplicaSet: `kubectl describe rs` shows `FailedCreate ... failed quota: team-quota: must specify limits.cpu,limits.memory`. `kubectl describe quota` shows hard limits and what is used.

## The fix

Declare limits on the container so that three pods fit inside the quota: for 2 CPU / 2Gi, up to about 600m and 640Mi each. Choosing limits larger than the share gives a different message, `exceeded quota ... requested ... limited`, and only some pods start.

## In production

Quotas are guardrails that teams agree on; the answer to a quota rejection is rarely to raise it. Platform teams often pair a quota with a `LimitRange` that supplies defaults so developers do not hit "must specify" errors. A quota on `requests.*` would also make requests mandatory. Remember a controller retries with back-off, so a rollout restart can speed things up after changes.

## Commands worth remembering

- `kubectl describe rs <name>` and `kubectl get events --sort-by=.lastTimestamp`
- `kubectl describe quota`
- `kubectl set resources deployment <name> --limits=cpu=...,memory=...`
