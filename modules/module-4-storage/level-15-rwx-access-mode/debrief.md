# Debrief: ingest v2 and the volume nobody could share

**What was broken.** Two faults sat behind one stuck rollout. The new claim `shared-pvc` asked for `ReadWriteMany`, copied from a cloud cluster with a shared filesystem. This cluster's provisioner (local-path) offers only single-writer volumes and refuses the request. Separately, `ingest-data` uses `ReadWriteOncePod`, and a default rolling update starts the v2 pod before stopping v1: v2 cannot be scheduled while v1 holds the volume, and v1 will not stop until v2 is Ready.

**The evidence.** The pending pod's events complain that its PVC is in use by another pod (ReadWriteOncePod) or that its claim is unbound. `kubectl describe pvc shared-pvc` shows a provisioning failure about the supported access modes once the pod is no longer blocked. `kubectl get pvc -o yaml` shows both claims' `accessModes`.

**Why Kubernetes behaves this way.** `ReadWriteOnce` limits a volume to one node; `ReadWriteOncePod` to one pod in the cluster. Many writers need a storage system built for it (NFS, CephFS, EFS) and its own class. The access modes of a claim are immutable, so the claim is deleted and recreated. And a rollout that surges a replica always needs the resources of both pods at once, volumes included.

**The fix.** `strategy.type: Recreate` stops the old pod first (clear `rollingUpdate`, as the API rejects it with `Recreate`); and `shared-pvc` is recreated as `ReadWriteOncePod`. The spool is single-writer by design anyway. `ingest-data` is left alone: its data is the point.

**In production.** Pick the strategy at design time: stateful singletons with single-writer volumes use `Recreate` (and accept a short gap) or are StatefulSets with `OrderedReady`; truly shared data needs an RWX class. Test the second version's rollout, not only the first install.

**Commands worth remembering**
- `kubectl get pvc -o custom-columns=NAME:.metadata.name,MODES:.spec.accessModes,STATUS:.status.phase`
- `kubectl describe pod <pod>`: scheduling events mention RWOP conflicts.
- `kubectl explain deployment.spec.strategy`
