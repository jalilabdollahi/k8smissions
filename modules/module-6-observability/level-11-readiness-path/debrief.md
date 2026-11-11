## What was broken

Release 2.0 shipped a new nginx configuration in which the health endpoint is `/-/health`. The Deployment kept the readiness probe from release 1.9, `httpGet /healthz`, which in the new config falls through to nothing and returns 404. Every new pod stayed `0/1`.

## The evidence

`kubectl rollout status` reported 1 of 3 new replicas updated and then waited. `describe pod` on the new pod listed `Readiness probe failed: HTTP probe failed with statuscode: 404`: the container was running and answering, only the path was wrong. The new ConfigMap, `docs-site-conf-v2`, lists the paths the server really has.

## Why Kubernetes behaves this way

With `maxSurge: 1` and `maxUnavailable: 0` a rolling update starts one new pod and only removes an old pod once the new one is Ready. A pod whose readiness probe fails never counts as available, so the update stalls without breaking anything: the old pods keep serving, which is why nobody noticed. That is the safe behaviour, and the reason this looks like an incident only to the pipeline.

## The fix

Update the probe path to the endpoint the new version really exposes. Pointing the probe at `/` would also give a 200 here, but a probe should test a path that reflects health, not just that nginx is up. Removing the probe makes the rollout finish and gives up the protection.

## In production

Keep the probe path next to the application config in the same change, and let CI hit the probe path of the new image. `progressDeadlineSeconds` marks a stalled rollout as failed so alerts can fire.

## Commands worth remembering

- `kubectl rollout status deploy/<name>` and `kubectl rollout history deploy/<name>`
- `kubectl describe pod <pod>` (Events)
- `kubectl get cm <name> -o yaml`
