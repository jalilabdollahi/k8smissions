## What went wrong

The primary cluster's lease expired (stale `renewTime`). The failover controller detected the expired lease but `failover-enabled: false` prevented automatic promotion of the secondary. The system entered a state with no active leader and no way to self-heal — all writes blocked until manual intervention.

## Fix

```yaml
metadata:
  annotations:
    control-plane.alpha.kubernetes.io/leader: '{"holderIdentity":"secondary-cluster","acquireTime":"2026-06-29","renewTime":"2026-06-29","leaderTransitions":1}'
data:
  failover-enabled: 'true'
  active-cluster: secondary
  passive-cluster: primary
  sync-status: synced
```

## Why this matters

Leader election lease-based patterns (used by Kubernetes controller-manager, scheduler, and custom operators) require the leader to periodically renew its lease. Lease renewal acts as a heartbeat — if the lease expires, the standby knows the leader is dead and can acquire leadership.

Operational checklist for failover design:
1. **Enable failover**: `failover-enabled: false` is appropriate during maintenance windows only — never leave it disabled long-term
2. **Verify sync before failover**: only failover when `sync-status: synced` — failing over with stale data causes data loss
3. **Increment leaderTransitions**: helps audit how many times leadership has changed
4. **Test failover regularly**: run chaos drills to verify the failover path actually works before you need it in production