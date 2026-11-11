**What was broken.** Two independent hook problems. The migration Job was annotated as a `PostSync` hook, so Argo would run it only after the Deployment in the Sync phase became healthy. The new pods refuse to become ready until the schema is at version 3, so the sync waited for health forever and the hook never ran. That deadlock has no timeout: the operation stays `Running` until someone ends it. Once the Job is a `PreSync` hook, the second problem appears: its pod reads the ConfigMap `migrations` through `configMapKeyRef`, but that ConfigMap is an ordinary resource of the Sync phase, so at PreSync time it does not exist (`CreateContainerConfigError`).

**The evidence.** The operation message `waiting for healthy state of apps/Deployment/ledger-api` with no Job in the namespace, then `describe pod` events naming the missing ConfigMap.

**Why Argo behaved that way.** Phases run in order and every phase must succeed (and its resources be healthy) before the next begins. Hooks are separate objects that are not part of the desired state, and a running operation is finished or terminated, never replaced by a newer commit.

**The fix.** `PreSync` for the Job, and the ConfigMap created with it as a hook in an earlier wave. A manual `curl` to the schema service would not release the sync. Terminate the stuck operation (the status phase `Terminating`) and request a fresh sync.

**In production.** Migrations belong in PreSync and must be idempotent: this one answers 409 when the version is already applied, so a repeated sync is harmless. Keep `activeDeadlineSeconds` on hook Jobs so a broken one fails instead of hanging the release.

**Commands worth remembering.**
- `kubectl -n argocd get app NAME -o jsonpath='{.status.operationState}'`
- `kubectl describe pod -l job-name=NAME`
- `kubectl -n argocd patch app NAME --type merge -p '{"operation":{"sync":{}}}'`
