## What went wrong

`persistentVolumeReclaimPolicy: Delete` on a PV intended for database storage. If the bound PVC is ever deleted — accidentally or during a cleanup — the underlying data is gone immediately and permanently.

## Fix

In manifest.yaml:

```yaml
spec:
  persistentVolumeReclaimPolicy: Retain
```

## The three reclaim policies

- `Retain` — PV keeps data after PVC deletion; admin must manually recover or clean up
- `Delete` — PV and backing storage are automatically deleted when PVC is deleted
- `Recycle` — deprecated; do not use

## This is different from level-9

Level 9 showed the aftermath — data already gone. This level is the prevention: catching the wrong policy before it causes data loss. In real teams, reviewing PV reclaim policies is part of production readiness checks.