## What was broken

Pipeline `release-ledger` sets the image, waits 30 seconds for the rollout, and has a `finally` Task `rollback` that runs `kubectl rollout undo`. Last week's bad tag made the rollout time out and the run ended Failed, yet `rollback` never started. Even if it had, the Deployment kept no previous ReplicaSet to return to.

## The evidence

`status.skippedTasks` of `release-ledger-0907` listed `rollback` with the reason that its `when` expression evaluated to false. Its guard compared `$(tasks.status)` with `Error`, a string Tekton never produces. `kubectl rollout history deployment/ledger-api` showed no revisions at all, and `revisionHistoryLimit: 0` explained why.

## Why Kubernetes and Tekton behaved this way

`finally` Tasks start regardless of failures, but a `when` guard is still evaluated, and it is a plain string comparison against the aggregate status (`Succeeded`, `Failed`, `Completed` or `None`). A typo there is not an error; the Task is simply skipped. A Deployment's rollback is not a stored copy of the old spec: it re-activates an older ReplicaSet, and the controller garbage-collects those down to `revisionHistoryLimit`. At zero there is nothing left.

## The fix

Guard `rollback` with `Failed` and keep at least a few revisions on the Deployment. Both defects had to be fixed: either one alone leaves the bad image in production.

## In production

Rollbacks that depend on cluster history are fine for stateless services; for anything with a schema change, an automatic undo can make things worse, so many teams page a human instead. Keep the default revision history (10) rather than trimming it.

## Commands worth remembering

- `kubectl get pipelinerun NAME -o jsonpath='{.status.skippedTasks}'`
- `kubectl rollout history deployment/ledger-api`
- `kubectl explain pipeline.spec.finally.when`
