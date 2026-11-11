# Debrief: the database that never started

**What was broken.** The `orders-db` Deployment mounts a claim named `orders-db-data`, but only `orders-data` was ever created. The pod could not be scheduled because a pod that references a missing PersistentVolumeClaim stays Pending.

**The evidence.** `kubectl describe pod` printed `persistentvolumeclaim "orders-db-data" not found` in its Events. The `Pending` claim everyone was staring at was a red herring: the default StorageClass `standard` uses `volumeBindingMode: WaitForFirstConsumer`, so a claim stays `Pending` until some pod that uses it is scheduled. An unused claim that is Pending is the normal, healthy state.

**Why Kubernetes behaves this way.** Delayed binding lets the provisioner pick a volume on the node where the pod will actually run. That matters for node-local storage like the local-path volumes in kind: the volume is created only after the scheduler has chosen a node. The side effect is that `kubectl get pvc` alone cannot tell you whether a claim is broken.

**The fix.** Create the claim the pod asks for, or change the Deployment to use the claim that exists. Once the pod is scheduled the claim binds and the pod starts.

**In production.** Claim names usually come from Helm values or a manifest that was renamed in one place only. When a pod is Pending, read the pod's own events before touching storage objects. Cloud classes often use `Immediate` binding, where a Pending claim does indicate a provisioning problem, so know which mode your class has.

**Commands worth remembering**
- `kubectl describe pod <pod>`: the scheduler's reasons are in Events.
- `kubectl get sc` / `kubectl get sc <name> -o yaml`: see the binding mode.
- `kubectl get pvc,pv`: which claim is bound to which volume.
