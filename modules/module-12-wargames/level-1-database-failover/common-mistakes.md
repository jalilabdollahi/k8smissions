**Deleting the PVC (or the StatefulSet with its claim) to get the pod to schedule.** The pod starts, but on a brand new empty volume: `entry-0001` is gone and the validator reports it. The pod was only waiting for its node, not for a new disk.

**Fixing the pod and stopping there.** A Running `ledger-db-0` does not mean the app can use it: the Service had no endpoints and the NetworkPolicy still dropped the app's traffic. After each fix, test the path again with a write through `ledger-app`.

**Deleting the NetworkPolicy to make the timeouts go away.** Traffic flows, but the database is now open to every pod in the cluster. The validator reaches the database from an unlabelled pod and fails if that works. Correct the selector instead.
