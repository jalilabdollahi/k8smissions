# Debrief: three replicas, one disk

**What was broken.** `web-servers` asked for 3 replicas, each mounting the ReadWriteOnce claim `site-content`, and also carried a hard topology spread constraint copied from the cloud cluster. The volume lives on one node, so each replica must run there; the constraint refuses to put a second replica on a node while other nodes are empty. Nothing can satisfy both, so two pods stayed Pending.

**The evidence.** `kubectl get pods -o wide` showed a single Running pod and its node. `kubectl describe pod` on a Pending pod listed two filter reasons from the scheduler: topology spread and volume node affinity. The PV's `nodeAffinity` named the node that holds the data.

**Why Kubernetes behaves this way.** ReadWriteOnce means one node at a time can mount the volume, and a node-local volume additionally carries node affinity, which the scheduler treats as a hard filter. Many pods on the same node may share a RWO volume. Spread constraints with `DoNotSchedule` are also hard filters, so a pod that fails any one filter is Pending.

**The fix.** Relax the spread rule to `ScheduleAnyway` (or drop it), keeping the single claim. Bigger disks, extra claims or lowering replicas do not meet the goal: the content must be shared by three replicas.

**In production.** The honest way to spread replicas across nodes is a volume that supports ReadWriteMany (NFS, CephFS, EFS) or content baked into the image or pulled from object storage at start. kind has no RWX provisioner, so the volume stays on one node here and we gave up node spreading instead.

**Commands worth remembering**
- `kubectl get pods -o wide`: which node each pod is on.
- `kubectl get pv <name> -o yaml`: `spec.nodeAffinity` of a local volume.
- `kubectl explain pvc.spec.accessModes`
