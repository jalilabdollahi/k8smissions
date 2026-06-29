## What went wrong

`persistentVolumeReclaimPolicy: Delete` — when the PVC was deleted, Kubernetes automatically deleted the PV and its backing storage. The data is permanently gone.

## Fix

In manifest.yaml, change the PV:

```yaml
spec:
  persistentVolumeReclaimPolicy: Retain
```

## Reclaim policy lifecycle with Retain

1. PVC deleted → PV status changes from `Bound` to `Released`
2. PV data is preserved on disk
3. A human administrator reviews, recovers, or manually deletes the PV
4. A new PVC can be manually bound to the released PV by setting `spec.claimRef`

## Rule of thumb

For any PV holding data you care about, always use `Retain`. `Delete` is convenient for ephemeral test environments but dangerous in production.