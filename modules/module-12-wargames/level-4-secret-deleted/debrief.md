**What was broken.** Secret `db-credentials` was deleted in the middle of a rotation that never happened on the database side. Two consumers needed it: the `billing-api` Deployment (key `password`) and the `invoice-export` CronJob (key `DB_PASS`). A rollout started right after the deletion left two old pods serving and two new pods unable to start.

**The evidence.** `get pods` shows `CreateContainerConfigError` and `describe pod` names the missing Secret. The old pods looked healthy because environment variables are copied into a container when it starts: deleting a Secret does not touch running pods. That is also where the password could be recovered. A made-up password lets pods become Ready (the readiness probe does not touch the database) and then every write answers 502, with `password authentication failed` in the `billing-db` log.

**Why Kubernetes behaved this way.** The kubelet resolves `secretKeyRef` when it creates a container; if the object or key is missing the container cannot be created and the kubelet retries. A rollout with `maxUnavailable: 1` removes old pods as new ones become ready, so the stuck new pods did not take the service down, only the safety margin. The CronJob fails only when it next creates a pod, which is why it would have broken at night.

**The fix.** Recover the real value from a live pod, recreate the Secret with every key the consumers reference, and let the retries finish the rollout.

**In production.** Keep Secrets in a secret manager and sync them (External Secrets, sealed secrets) so a deletion is recreated; never rotate by deleting; keep a readiness check that exercises the dependency.

**Commands to remember.** `kubectl exec <pod> -- printenv`, `kubectl get secret <name> -o jsonpath='{.data}'`, `kubectl create job --from=cronjob/<name> <job>`.
