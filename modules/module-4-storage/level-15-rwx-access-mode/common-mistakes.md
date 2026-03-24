# Common Mistakes — The Exclusive Mount

## Mistake 1: Patching accessModes on existing PVC

**Wrong approach:** kubectl patch pvc to change accessModes — this field is immutable

**Correct approach:** Delete the PVC and recreate; be sure no pods are using it and data is backed up

## Mistake 2: Assuming all storage supports RWX

**Wrong approach:** Requesting RWX from a cloud block volume (EBS, GCEPersistentDisk) — PVC stays Pending

**Correct approach:** Verify StorageClass provisioner supports RWX before requesting it
