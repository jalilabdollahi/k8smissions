# Common Mistakes — Chaos Unready

## Mistake 1: Running chaos experiments in production without PDB

**Wrong approach:** Uncontrolled chaos can kill too many pods — use PDB to limit chaos blast radius

**Correct approach:** Always set PDB minAvailable before running chaos experiments
