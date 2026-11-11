## What was broken

Both ledger Deployments looked configured for INFO, but `ledger-api` had `LOG_LEVEL=info` and the application only recognises upper-case names. Faced with an unknown value it fell back to DEBUG, which is the loudest setting: 25 lines per second per replica, thousands a minute across the two replicas, into a shared log pipeline.

## The evidence

Counting lines per pod with `kubectl logs -l tier=ledger --prefix --since=1m` pointed at `ledger-api` immediately. The first line of its log, `unknown LOG_LEVEL 'info' (valid: DEBUG, INFO, WARN, ERROR, CRITICAL), using DEBUG`, named the value, and the sibling Deployment showed the spelling that works.

## Why Kubernetes behaves this way

Kubernetes passes environment variables through untouched; it neither validates nor normalises them. How an unknown value is treated is a decision of each application. Many libraries fall back to the most verbose level, which is why a typo can flood a log pipeline rather than silence it. A change to the pod template starts a rollout; `kubectl logs` always shows the current container only, so counts after the fix come from the new pods.

## The fix

Set `LOG_LEVEL=INFO` on `ledger-api`. Setting `CRITICAL` would also quiet it, but the service would lose its WARN and ERROR lines, which are exactly what you need when something breaks.

## In production

Log levels belong in a ConfigMap shared by both services so a typo cannot affect one only, and applications should fail on unknown values instead of falling back to DEBUG. Alerts on log volume per workload catch this kind of regression.

## Commands worth remembering

- `kubectl logs -l <selector> --prefix --since=1m`
- `kubectl set env deploy/<name> KEY=value` and `kubectl set env deploy/<name> --list`
- `kubectl logs <pod> --tail=5`
