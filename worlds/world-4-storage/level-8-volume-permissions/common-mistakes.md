# Common Mistakes - Level 8: Permission Denied

## Fastest First Checks
```bash
kubectl get pv,pvc,storageclass -n k8smissions
kubectl describe pvc <name> -n k8smissions
kubectl describe pod <pod> -n k8smissions
```

## ❌ Mistake #1: Troubleshooting the app before the storage object

**What players try:**
Players look only at application logs in Permission Denied and skip PV/PVC status, mount definitions, or storage class details.

**Why it fails:**
If the claim never binds, mounts to the wrong path, or uses the wrong access mode, the app is only reporting the consequence.

**Correct approach:**
Start from volume mount path and file projection: inspect the claim, the backing volume or class, and how the pod mounts it.

**Key learning:**
Storage bugs are usually contract mismatches between claim, volume, and mount point.
## ❌ Mistake #2: Confusing persistent and pod-local state

**What players try:**
Players assume data behavior is identical across `emptyDir`, PVCs, and per-pod StatefulSet volumes.

**Why it fails:**
Different volume types have different lifecycles, sharing semantics, and safety characteristics.

**Correct approach:**
Choose the storage primitive that matches the workload lifecycle instead of copying a manifest pattern from another use case.

**Key learning:**
Persistence is a design choice in Kubernetes, not a default property of all volumes.
## ❌ Mistake #3: Ignoring access mode, key projection, or permissions

**What players try:**
Players fix only the resource name and miss the field the container actually relies on.

**Why it fails:**
The correct claim can still fail if it is mounted to the wrong path, exposed through the wrong key, or blocked by filesystem ownership.

**Correct approach:**
Check the exact path, key, access mode, and security context the app uses at runtime.

**Key learning:**
Working storage requires both correct attachment and correct in-container visibility.
## ❌ Mistake #4: Treating data operations as harmless

**What players try:**
Players delete or recreate storage objects quickly to 'start fresh'.

**Why it fails:**
Reclaim policy and binding behavior decide whether data survives. A fast reset can create irreversible loss in real clusters.

**Correct approach:**
Understand the storage lifecycle before deleting anything. Then validate the intended safe state: Use the validator to confirm the repaired state.

**Key learning:**
Storage fixes are part troubleshooting and part data protection discipline.

## What To Prove Before You Move On
- The claim or mount now matches the expected storage behavior.
- You verified access mode, mount path, or permissions at the place the app actually uses.
- Use the validator to confirm the repaired state.
