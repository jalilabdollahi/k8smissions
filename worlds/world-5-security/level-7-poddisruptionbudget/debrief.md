# PDB Blocks Node Drain

## Situation
PDB minAvailable: 3, Deployment replicas: 2. Node drain fails because it can't evict pods safely.

## Successful Fix
Change PDB minAvailable: 1  OR scale Deployment to 4+

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for PDB Blocks Node Drain.

## Concepts
PodDisruptionBudget, voluntary disruption, cluster upgrades, kubectl drain --ignore-daemonsets
