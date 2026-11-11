**What was broken.** Replication stopped for three independent reasons that surfaced one after another. A Lease still named a pod that was gone, with a duration of ten years, so no live replicator could become the leader. The `us` namespace admits traffic only from namespaces labelled `region=eu`, and `eu` had no such label. And the replication token in `us` carried a trailing newline from `echo`.

**The evidence.** Both replicator logs said `standby: lease eu-leader held by replicator-7c9 for another 315359999s`. After the lease was freed the log changed to `cannot reach us store: timed out`, which is how a NetworkPolicy drop looks from the client. Once the label was in place it became `us store answered HTTP 401`, and the replica logged `rejected write: bad or missing token`; `base64 -d | od -c` showed the final `\n`.

**Why Kubernetes behaved this way.** A Lease is a plain object: whoever holds it is whoever last wrote the name, and it only expires through `renewTime` plus `leaseDurationSeconds`, so a dead holder with a long duration blocks every standby. A `namespaceSelector` matches namespace labels, and namespaces are not labelled by default (except `kubernetes.io/metadata.name`). Secrets keep every byte, newline included, and environment variables are fixed when the container starts.

**The fix.** Delete or expire the lease, label the namespace, recreate the Secret byte-exact, restart the replica. The policy and the token check stay in force, which the validator proves from an outsider pod and with an unauthenticated write.

**In production.** Use short lease durations (15 s is typical), label namespaces as part of provisioning, create Secrets with `--from-file` or `printf`, and make consumers reload when a Secret changes.

**Commands to remember.** `kubectl get lease <name> -o yaml`, `kubectl get ns --show-labels`, `kubectl get secret <name> -o jsonpath='{.data.x}' | base64 -d | od -c`.
