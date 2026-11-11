**Deleting the NetworkPolicy in `us`.** Replication then reaches the replica and the sync step passes, but every namespace can now reach the `us` store. The validator probes it from `k8smissions` and expects no answer.

**Fixing the token with `echo` again.** `echo "value" | base64` adds the newline that broke it in the first place; use `printf`, `--from-literal`, or copy the bytes from the `eu` Secret. And a corrected Secret does nothing for the running replica until it restarts.

**Waiting for the lease to expire.** With a ten year duration it never will. A standby replicator will not break a lease it cannot prove dead; remove or expire it yourself, and check afterwards that the holder is one of the pods that actually exist.
