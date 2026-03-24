# Common Mistakes — Surprise Drain

## ❌ Increasing replicas instead of fixing the PDB
While increasing replicas also works, it wastes resources. Fix the PDB to match business availability requirements.

## ❌ Using --force on kubectl drain
This bypasses PDBs and can cause data loss for stateful workloads.
