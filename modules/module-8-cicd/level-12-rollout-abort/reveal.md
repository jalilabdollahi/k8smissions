Two defects, one in the Pipeline and one on the Deployment:

1. `rollback` has `when: input: $(tasks.status) operator: in values: ["Error"]`. The aggregate status is never `Error`: after a failed Task it is `Failed`. The Task was skipped every time. Change the value to `Failed`.
2. `ledger-api` has `revisionHistoryLimit: 0`, so Kubernetes deletes every old ReplicaSet and `kubectl rollout undo` answers "no rollout history found". Set it to 1 or more (`kubectl patch deployment ledger-api --type=merge -p '{"spec":{"revisionHistoryLimit":5}}'`).

A new release with a bad tag now ends Failed at `deploy`, `rollback` runs and the previous image returns.
