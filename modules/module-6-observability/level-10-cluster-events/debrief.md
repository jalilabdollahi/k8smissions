## What was broken

The visible failure was `inventory-sync` crash-looping with `cache: connection failed`. The cause was in another namespace: `inventory-cache` mounts Secret `cache-auth`, which was missing from `cache-tier`, so its pod sat in ContainerCreating and the Service had no endpoints. The cache also needs the same password the app sends, and the only copy was in the app's own Secret under a different name and key.

## The evidence

`kubectl get events -n k8smissions` only showed the app's restarts. `kubectl get events -A --sort-by=.lastTimestamp` (or `--field-selector type=Warning`) put the `FailedMount` event of the cache pod at the start of the timeline. Reading it, you learn the object, the namespace and the Secret name. The sync log said "connection failed" without a reason, which is typical for a client that only reports its own symptom.

## Why Kubernetes behaves this way

Events are namespaced objects with a short life, attached to the object they describe. A volume that cannot be set up blocks the pod before any container starts, so there is nothing to log. Secrets are namespaced and a pod can only reference Secrets from its own namespace; Kubernetes never copies them for you. The kubelet retries failed mounts with a back-off that grows to about two minutes, so even after fixing the cause the pod may wait.

## The fix

Create `cache-auth` in `cache-tier` holding the same password the app uses, with the key the volume expects (`password`). Then restart the cache pod, and the sync pod to skip its own back-off.

## In production

Copying a secret by hand drifts. Use an external secrets operator or one source of truth, and alert on `FailedMount` events cluster-wide.

## Commands worth remembering

- `kubectl get events -A --sort-by=.lastTimestamp`
- `kubectl get events -A --field-selector type=Warning,involvedObject.kind=Pod`
- `kubectl get secret <name> -o jsonpath='{.data.<key>}' | base64 -d`
