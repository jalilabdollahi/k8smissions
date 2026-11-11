**Inventing a new password.** The Secret exists, the pods start and the rollout completes, so it looks fixed, but the database was never rotated: every write returns 502 and the validator's writes fail. The value must come from a pod that still has the original.

**Creating the Secret with only the key the API uses.** `billing-api` becomes healthy and the CronJob stays broken until 02:30 when it creates its pod and gets `CreateContainerConfigError`. Check every `secretKeyRef` in the namespace, not just the Deployment that is on screen.

**Rolling back the Deployment.** `kubectl rollout undo` brings back a ReplicaSet whose pods still reference `db-credentials`; they are stuck just the same, and you have lost the running pods you needed to read the password from. Recover the value first.
