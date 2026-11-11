# Debrief: uploads that die with the pod

**What was broken.** `data-app` stored customer uploads in `/data`, which was an `emptyDir`. Everything looked durable because the team tested by restarting the container: an `emptyDir` survives that. It does not survive the pod being deleted, evicted or rescheduled by a drain, and then the files were gone.

**The evidence.** `kubectl get deployment data-app -o yaml` shows `emptyDir: {}` under `volumes` and no `persistentVolumeClaim` anywhere; `kubectl get pvc` is empty. The honest test is `kubectl delete pod` after an upload, not a container restart.

**Why Kubernetes behaves this way.** An `emptyDir` is created on the node when the pod is scheduled there, and its lifetime is the pod's. That is exactly right for caches and scratch space, so Kubernetes never warns about it. A PersistentVolumeClaim has its own lifecycle: the volume outlives any pod that mounts it.

**The fix.** Create a PVC and make the `uploads` volume use it. Note the trap in the patch: a strategic merge patch adds `persistentVolumeClaim` next to the existing `emptyDir` and the API rejects a volume with two sources, so use a JSON patch (`replace`) or `kubectl edit`. `/scratch` is deliberately left alone: moving temporary files to durable storage costs money and keeps garbage forever.

**In production.** Decide per directory: durable data on a PVC, caches and temp files on `emptyDir` (use `sizeLimit`, and `medium: Memory` for tmpfs when needed). For several replicas, a Deployment sharing one RWO claim is the wrong tool; use a StatefulSet with `volumeClaimTemplates`.

**Commands worth remembering**
- `kubectl get deploy <name> -o jsonpath='{.spec.template.spec.volumes}'`
- `kubectl delete pod <pod>`: the persistence test that matters.
- `kubectl explain pod.spec.volumes.emptyDir`
