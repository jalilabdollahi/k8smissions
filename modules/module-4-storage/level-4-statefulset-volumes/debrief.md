# Debrief: every replica writes to the same disk

**What was broken.** The StatefulSet used a plain `persistentVolumeClaim` volume that names one claim, `pgdata-shared`. Every member mounted the same directory. Member 0 claimed it by writing its name into `node-id`; member 1 saw a foreign owner and exited, and because the StatefulSet starts members in order and waits for each to be Ready, member 2 was never created.

**The evidence.** `kubectl get pvc` showed exactly one claim for a three-member set, `kubectl logs postgres-cluster-1` named the owner of the data directory, and the manifest had no `volumeClaimTemplates`. The healthy pattern is one claim per ordinal, `pgdata-postgres-cluster-0`, `-1`, `-2`.

**Why Kubernetes behaves this way.** A StatefulSet gives each pod a stable identity and, through `volumeClaimTemplates`, its own claim that outlives the pod. The controller creates the claims, and a rescheduled `postgres-cluster-1` gets the same `pgdata-postgres-cluster-1` back. A fixed `claimName` bypasses all that: it is just a shared volume.

**The fix.** `volumeClaimTemplates` is immutable on an existing StatefulSet, so the StatefulSet must be deleted and created again with the template, and the shared claim removed. Deleting with `--cascade=orphan` would leave pods still mounting the old claim, which is why a full delete is simpler here.

**In production.** Deleting a StatefulSet does not delete its claims; always check what a claim holds before removing it. Here the shared claim held nothing worth keeping. For real data, take a backup first, and never reuse claims between members.

**Commands worth remembering**
- `kubectl get pvc -l app=<name>`: one claim per member.
- `kubectl explain statefulset.spec.volumeClaimTemplates`
- `kubectl delete statefulset <name> --cascade=orphan`: keeps pods, useful for some edits.
