# Common Mistakes — Stale Reconciliation

## Mistake 1: Ignoring generations entirely

**Wrong approach:** Not tracking generation — controller churns on every event even when nothing changed

**Correct approach:** Always update observedGeneration after reconciliation to enable efficient generation-based guards
