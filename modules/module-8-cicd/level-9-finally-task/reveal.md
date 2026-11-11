`teardown` is an ordinary Task at the end of the chain, so it is skipped when anything earlier fails, and it also takes its target from a result of `provision`.

1. `kubectl get pods,services -l app=scratch`: 14 leftovers; `kubectl get resourcequota`: 14/16 Services.
2. Edit Pipeline `integration-test`: move `teardown` to `spec.finally` (no `runAfter`).
3. Pass it no result of `provision`: when `provision` fails before writing `name`, the result never exists and a finally Task that references it never starts, so the run hangs in Running. Delete `scratch-$(context.pipelineRun.name)` instead, the name `provision` derives from the same run name.
4. Delete the 14 old leftovers once: `kubectl delete pod,service -l app=scratch`.
5. A failing run still ends Failed, and leaves nothing behind.
