1. `kubectl describe job nightly-import` shows condition `Failed`, reason `DeadlineExceeded`: the Job ran longer than `activeDeadlineSeconds: 25` in total.
2. Each shard takes about 12s plus pod start-up, so three shards need about 45s; the Job was stopped before shard 3 could finish.
3. The deadline of a finished Job cannot be edited meaningfully, and the Job will not restart. Delete it and create it again with a larger `activeDeadlineSeconds` (for example 300) or none.
4. Wait for `kubectl get job nightly-import` to show `3/3` completions.
