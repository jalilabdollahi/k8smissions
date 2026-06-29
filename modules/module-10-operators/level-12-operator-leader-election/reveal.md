## What went wrong

With `--leader-elect=false`, both operator replicas run as active controllers simultaneously. They race to reconcile the same objects: replica A sets `replicas: 3`, replica B reads the state and also sets `replicas: 3`, but they interleave on conflict resolution and fight over the state. Resources flap and never stabilize.

## Fix

```yaml
args:
- --leader-elect=true
- --leader-elect-lease-duration=30s
```

## Why this matters

Controller-runtime implements leader election via a Kubernetes `Lease` object. Only the pod holding the lease actively reconciles; others run as standbys watching the lease. If the leader pod crashes, the lease expires (after `lease-duration`) and a standby acquires it and becomes the new leader. This is active-passive HA: one active reconciler at a time, no split-brain. The trade-off: `lease-duration` is the time between leader failure and new leader election — shorter means faster failover but more false-positive leadership changes under network blips.