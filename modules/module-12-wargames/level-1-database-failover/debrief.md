**What was broken.** Three faults stood in a row between `ledger-app` and its data. The drill had cordoned the node that holds the database's local volume, so `ledger-db-0` sat Pending. The Service `ledger-db` selected a `role=primary` label the StatefulSet pod never had, and the NetworkPolicy admitted `tier=app` while the app pods are `tier=backend`.

**The evidence.** The application error ("database unavailable") points at the database, but `get pods` shows the database is not even running, and `describe pod` names the reason: `1 node(s) were unschedulable, 1 node(s) had volume node affinity conflict`. After the node is back, the app log changed from `Connection refused` (Service with no endpoints: kube-proxy rejects) to `timed out` (NetworkPolicy drops silently). Those two error texts tell the two network faults apart without any tooling.

**Why Kubernetes behaved this way.** A local PersistentVolume carries a `nodeAffinity`, so a pod that claims it can only run on that node. The scheduler cannot move it elsewhere, and a cordon is respected even if the pod is the only thing that could use that node. StatefulSet volumes survive pod deletion, which is why the seeded entry was still there.

**The fix.** Uncordon the node, correct the Service selector, correct the policy selector. Deleting the PVC to get a new volume would have started an empty database; deleting the policy would have reopened the database to every pod.

**In production.** Replicated storage (or a database with replicas on other nodes) avoids the node pin; drills should uncordon in a `trap`/finally step; and a policy change should be tested with a pod of the right and the wrong labels.

**Commands to remember.** `kubectl describe pod <pod>` (Events), `kubectl get endpointslices -l kubernetes.io/service-name=<svc>`, `kubectl get pv -o yaml | grep -A8 nodeAffinity`.
