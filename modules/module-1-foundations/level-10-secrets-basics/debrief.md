## What was broken

The credentials were moved into Secret `reports-db` under the keys `db-user` and `db-password`, but Deployment `reports-api` references `key: password`. The kubelet cannot build the container's environment without that key, so it never created the container.

## The evidence

`kubectl get pods` showed `CreateContainerConfigError`. There were no logs, because no container existed. `kubectl describe pod` carried the event `Error: couldn't find key password in Secret k8smissions/reports-db`. It names the Secret, so the Secret is present, and it names the missing key. Listing the Secret's keys then reveals the right one.

## Why Kubernetes behaved this way

Environment injection happens in the kubelet before the container starts. A `secretKeyRef` to a missing Secret or key is an error unless `optional: true` is set, and the pod waits in this state, retrying, so a Secret created later heals it. A Secret's `data` values are base64 encoded, but its keys are plain text.

## The fix

Point the reference at the real key. Because that is a template change, the Deployment rolls out new pods. Creating a second key with a guessed value would start the pods but the database would answer `access denied`; the value has to come from the existing Secret.

## In production

Keep the Secret's key names in one place (a chart value or a convention) and have CI render the manifests against them. Never paste decoded secret values into tickets; use `kubectl get secret ... -o jsonpath` and `base64 -d` only when you must.

## Commands worth remembering

- `kubectl describe pod <pod>` (Events)
- `kubectl get secret <name> -o jsonpath='{.data}'`
- `kubectl get secret <name> -o jsonpath='{.data.<key>}' | base64 -d`
