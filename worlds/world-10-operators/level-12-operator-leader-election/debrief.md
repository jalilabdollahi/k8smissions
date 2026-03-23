# Split Brain

## What Was Broken
The operator had --leader-elect=false with 2 replicas. Both pods ran full reconciliation loops simultaneously. They competed to update resources — patches from one were immediately overwritten by the other, causing flapping.

## The Fix
Enable leader election with --leader-elect=true. The Kubernetes Lease mechanism ensures only one replica is active.

## Why It Matters
Operator HA with leader election: 2+ replicas, leader election enabled. Active leader holds the Lease. Leader dies → lease expires (configurable duration) → standby becomes leader. Fast failover, no split-brain, simple to configure.

## Pro Tip
Check the current leader: kubectl get lease my-operator -n operators -o yaml. The holderIdentity field shows the pod name that currently holds leadership.

## Concepts
leader election, Lease, operator HA, split brain, --leader-elect, controller-runtime
