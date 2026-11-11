Each replica takes its Lease name from its own pod name (`LEASE_NAME` comes from `metadata.name`), so every pod creates and wins a lease of its own and both act as leader. The fix is a single shared lease name in the Deployment, while `POD_NAME` stays as the identity:

```bash
kubectl -n k8smissions set env deploy/orders-operator LEASE_NAME=orders-operator-leader
kubectl -n k8smissions rollout status deploy/orders-operator
```

After the rollout one pod holds `orders-operator-leader`, the other logs nothing and waits; if the leader dies, the survivor takes the lease once it has expired (10 seconds) and reconciles. The old per-pod leases are no longer renewed and can be deleted.
