## Scaling to one replica

The two pods can no longer fight, so `lastWriter` stops flipping, but the operator is no longer highly available and the failover check (delete the leader, a new Order must still be reconciled) cannot pass. The level is about making election work.

## Pointing the lease at a shared name but breaking the identity

If `POD_NAME` is also made identical, both pods consider themselves the holder of the same lease (`holderIdentity` matches) and both keep renewing it, which is split brain again. Only the lease name is shared; the identity stays per pod.

## Looking only at `kubectl get lease`

Two leases with recent renewals look like a healthy election. The giveaway is that there are two of them, with different holders, for one operator.
