1. `kubectl logs job/<latest>` shows the policy is rejected: `LowNodeUtilization` is listed under `plugins.deschedule`, but it is a balance plugin. Move it to `plugins.balance.enabled`.
2. After that the Job completes but evicts nothing: with `thresholds` of 1% for cpu, memory and pods, no node, not even the idle worker, is "underutilized", so the plugin logs that there is nothing to do. Raise them (for example 20 / 20 / 20, below `targetThresholds` of 50 / 50 / 50).
3. Apply the edited ConfigMap, then start a fresh Job so it reads the new policy instead of waiting for the next minute:
   `kubectl -n k8smissions create job --from=cronjob/descheduler descheduler-manual`
4. The Job logs `Evicted pod` lines; the ReplicaSet recreates the pods and the scheduler puts them on the idle worker.
