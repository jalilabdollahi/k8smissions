# Common Mistakes — Deployment Stuck

## Mistake 1: Deleting the PDB to unblock deployment

**Wrong approach:** Removing PDB — then no protection against node drain, cluster upgrades, etc.

**Correct approach:** Lower minAvailable to N-1 or maxUnavailable to 1; don't delete the PDB
