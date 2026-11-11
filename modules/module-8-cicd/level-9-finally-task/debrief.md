## What was broken

Each `integration-test` run creates a scratch Pod and Service named `scratch-<run name>`, and removes them in a final Task `teardown`, chained after `smoke` with `runAfter`. When `provision` or `smoke` failed, Tekton skipped everything after it, including `teardown`. Fourteen failed runs left fourteen environments, and the namespace's Service quota was nearly full.

## The evidence

`kubectl get pipelinerun -o yaml` of a failed run listed `teardown` under `skippedTasks`. The leftovers carried the label `run=<name of the failed run>`. A test run with `scenario=bad-fixture` made `provision` fail after it had already created the objects.

## Why Tekton behaved this way

In `spec.tasks` a Task starts only when the Tasks it depends on succeeded; a failure skips the rest of the graph. Cleanup does not belong there. `spec.finally` Tasks start after all regular Tasks are done, finished or skipped, and failure does not stop them. They may see `$(tasks.status)` and the results of Tasks that produced them. `provision` writes its result only at the end of its last step, so when it fails the result never exists, and a `finally` Task that depends on `$(tasks.provision.results.name)` never starts: the failed run stays in Running instead of cleaning up. The name must come from something that always exists, the PipelineRun name.

## The fix

`teardown` moves into `finally`, derives `scratch-$(context.pipelineRun.name)` and deletes with `--ignore-not-found`, so it is also safe when `provision` failed before creating anything. The old leftovers need a one-off `kubectl delete`.

## In production

Ownership is cleaner than naming: put an ownerReference or a TTL label on scratch objects, or create them as a PipelineRun-owned resource. A quota on the namespace is what turned a silent leak into an outage; keep it.

## Commands worth remembering

- `kubectl get pipelinerun NAME -o jsonpath='{.status.skippedTasks}'`
- `kubectl get pods,svc -l app=scratch --show-labels`
- `kubectl describe resourcequota`
