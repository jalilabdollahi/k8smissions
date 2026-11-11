Four faults in four areas:

1. `shop-web` runs as ServiceAccount `shop-runner`, which does not exist, so the ReplicaSet creates no pods (`FailedCreate`). `kubectl create serviceaccount shop-runner`.
2. PVC `shop-data` names StorageClass `fast-ssd`, which does not exist; the field is immutable. Delete `db-migrate` (its pod references the claim), delete the PVC, and re-create it with `storageClassName: standard` (the cluster default is fine too). It binds when the migration pod is scheduled.
3. `db-migrate` is invoked with `--schema=v9`, unknown to the script (`known: v6 v7`), and the web init container waits for `v7`. A Job's pod template cannot be edited: delete it and create it again with `--schema=v7` (v6 would run but leave the web pods waiting).
4. The Ingress backend asks for port name `http`; the Service port is named `web`. Patch the Ingress to `web` (or to number 80).

The migration cannot run until the PVC binds, so the storage fix comes before the Job.
