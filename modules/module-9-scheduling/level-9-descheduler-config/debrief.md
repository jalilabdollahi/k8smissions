## What was broken

Two independent mistakes in the Descheduler policy stood between the team and a balanced cluster. `LowNodeUtilization` was enabled under `plugins.deschedule`, so the Job failed at startup. Once that was fixed, `thresholds` of 1% meant no node counted as underutilized, so the plugin quietly did nothing.

## The evidence

The first failing Job's log named the plugin and the extension point it could not be used for. After the move, Jobs showed `Completed` with no `Evicted pod` lines and a verbose message that no node was underutilized. `kubectl describe node` showed the idle worker still had a few percent of its CPU and pods reserved by system pods.

## Why Kubernetes behaves this way

The Descheduler is not part of the scheduler: it is a separate program that evicts pods so the real scheduler can place them better. LowNodeUtilization compares node usage (computed from pod requests) with two limits: below all `thresholds` is underutilized, above any of `targetThresholds` is overutilized, and it only evicts from the second group when the first group exists. Jobs read the policy ConfigMap at start, so edits only apply to the next Job.

## The fix

Enable the plugin under `balance`, raise the thresholds so the idle worker qualifies, and start a Job. The loaded worker then drops to about the target and the evicted pods are rescheduled on the other one.

## In production

The Descheduler respects PodDisruptionBudgets and skips pods without owners, local storage and system-critical priority. Run it with a narrow `evictableNamespaces`, and rely on topology spread constraints, not the Descheduler, for placement that must hold at schedule time.

## Commands worth remembering

- `kubectl create job --from=cronjob/<name> <job>`
- `kubectl logs job/<name>` (use `--v=4` in the args for detail)
- `kubectl describe node <node> | grep -A8 "Allocated resources"`
