## What went wrong

`storageClassName: premium-ssd` — no StorageClass with this name exists. The dynamic provisioner only watches for PVCs that request a class it manages. Since no provisioner knows about `premium-ssd`, the PVC is permanently Pending.

## Fix

In manifest.yaml, change the PVC:

```yaml
storageClassName: standard
```

## How dynamic provisioning works

1. PVC created with a storageClassName
2. The provisioner for that class detects the new PVC
3. Provisioner creates a matching PV and binds it
4. Pod can now mount the volume

If step 2 never happens (wrong class name), the chain stops at step 1.