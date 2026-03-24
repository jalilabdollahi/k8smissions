# Region Lag

## What Happened
The primary cluster annotation in the leader-election ConfigMap had a stale renewTime from over a year ago. The failover controller saw that the leader hadn't renewed its lease and expected a failover, but failover-enabled was set to false, leaving the cluster in a broken state.

## The Fix
Update the leader-election ConfigMap to reflect the correct active cluster and enable failover:
```bash
kubectl patch configmap leader-election -n k8smissions \
  --patch '{"data":{"failover-enabled":"true","sync-status":"synced"}}'
```

## Key Lessons
- **Leader election leases** — controllers use ConfigMap/Lease annotations with TTLs
- **Multi-cluster failover** requires regular lease renewals and monitoring
- **Lease objects** — prefer the dedicated `coordination.k8s.io/v1 Lease` resource over ConfigMap annotations
- **Regular DR drills** — test failover in non-production environments regularly
