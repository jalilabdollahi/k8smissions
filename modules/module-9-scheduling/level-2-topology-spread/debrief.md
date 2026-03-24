# Uneven Spread

## What Was Broken
No TopologySpreadConstraint was defined. The scheduler placed all 4 pods on a single node (or heavily skewed). A node failure would take down all replicas simultaneously.

## The Fix
Add a TopologySpreadConstraint with maxSkew: 1 and topologyKey: kubernetes.io/hostname to spread pods evenly across nodes.

## Why It Matters
For zone-level HA, use topologyKey: topology.kubernetes.io/zone. Many cloud clusters label nodes with this key. Combine zone-spread and node-spread constraints for maximum HA.

## Pro Tip
whenUnsatisfiable: DoNotSchedule is the safe choice — don't schedule a pod that would violate maxSkew. ScheduleAnyway relaxes the constraint when no valid placement exists.

## Concepts
TopologySpreadConstraint, maxSkew, hostname topology, HA, pod spread
