## What was broken

Deployment `invoice-render` asks for `requests.memory: 64Mi` and `limits.memory: 512Mi`, a ratio of 8. A LimitRange called `team-defaults` in the namespace allows a ratio of at most 2 for memory. The LimitRange admission plugin therefore refused every pod the ReplicaSet tried to create, and the Deployment sat at 0/3.

## The evidence

`kubectl get pods` was empty, which is the signature of an admission failure: the pods were never created. `kubectl describe rs` listed `FailedCreate` events with `maximum memory limit to request ratio per Container is 2, but provided ratio is 8.000000`, and `kubectl describe limitrange team-defaults` showed the rule.

## Why Kubernetes behaved this way

A LimitRange is checked when a pod is created, not when the Deployment is. So the Deployment was accepted, and the failure showed up one level down, on the ReplicaSet. The ratio rule is about burstiness: a big gap between request and limit lets a pod use far more than the scheduler accounted for.

## The fix

Size request and limit together. A render peaks at about 360 MiB, so the limit stays at 512Mi and the request goes to 256Mi (ratio 2). Shrinking the limit to meet the ratio would trade an admission error for OOM kills under load; deleting the LimitRange would remove the team's rule.

## In production

Read `describe limitrange` and `describe resourcequota` before writing manifests for a shared namespace. Put such rules in the starter templates, so the manifest passes on the first try. For events, remember they expire after about an hour, so check early.

## Commands worth remembering

- `kubectl describe rs <name>` / `kubectl get events --sort-by=.lastTimestamp`
- `kubectl describe limitrange`
- `kubectl set resources deployment <name> --requests=... --limits=...`
