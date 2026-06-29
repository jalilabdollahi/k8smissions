## What went wrong

`accessModes: [ReadWriteOnce]` restricts the volume to a single node. When multiple pods on different nodes try to mount it simultaneously, only the first node wins. Subsequent pods on other nodes are blocked — they either fail to mount or wait indefinitely.

## Fix

In manifest.yaml:

```yaml
spec:
  accessModes:
  - ReadWriteMany
```

Delete and recreate the PVC (accessModes are immutable on bound PVCs):

```bash
kubectl delete pvc shared-pvc -n k8smissions
```

Then apply the updated manifest.

## Difference from level-3

Level 3 required changing both the PV AND PVC access modes, plus had a full Deployment scenario. This level isolates the PVC-only change and adds the important detail: you cannot mutate an existing bound PVC — delete and recreate is the only path.